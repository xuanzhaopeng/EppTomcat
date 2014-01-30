<%-- 
    Document   : buildepp
    Created on : 23 janv. 2014, 00:57:10
    Author     : xuanzhaopeng
--%>

<%@page import="fr.ece.epp.tools.Utils"%>
<%@page import="java.security.MessageDigest"%>
<%@page import="java.io.PrintWriter"%>
<%@page import="java.io.StringWriter"%>
<%@page import="java.io.InputStreamReader"%>
<%@page import="java.io.BufferedReader"%>
<%@ page import ="java.sql.*" %>
<%@ page import ="javax.sql.*" %>
<%@page import="java.io.File"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    public String getValue(String target) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            md.update(target.getBytes());
            byte[] digest = md.digest();
            StringBuffer sb = new StringBuffer();
            for (byte b : digest) {
                sb.append(Integer.toHexString((int) (b & 0xff)));
            }
            return sb.toString();
        } catch (Exception ex) {
            return null;
        }
    }

    public boolean insertHistory(String name, String value, String version) {

        String build_url = "/download?id=" + name;
        String query = "INSERT ignore INTO epp_history (build_value,build_url,build_version) VALUES ('" + value + "','" + build_url + "','" + version + "')";

        try {
            Connection con = DriverManager.getConnection("jdbc:mysql://localhost/eclipseplusplus", "root", "");
            Statement st = con.createStatement();

            st.executeUpdate(query);

            st.close();
            con.close();
            return true;
        } catch (SQLException sqle) {
            System.out.println(query);
            System.out.println(sqle.getMessage());
            return false;
        }
    }

    public String searchHistory(String value, String version) {
        String query = "SELECT build_url FROM epp_history WHERE build_value = '" + value + "' AND build_version='" + version + "'";
        try {
            Connection con = DriverManager.getConnection("jdbc:mysql://localhost/eclipseplusplus", "root", "");
            Statement st = con.createStatement();
            ResultSet rs = st.executeQuery(query);
            if (rs.next()) {
                return rs.getString("build_url");
            }

            rs.close();
            st.close();
            con.close();

        } catch (SQLException sqle) {
            System.out.println(query);
            System.out.println(sqle.getMessage());
            return null;
        }
        return null;
    }
%>
<%
    response.setContentType("text/html;charset=UTF-8");
    Boolean foundCache = false;
    String downloadUrl = "";
    try {
        Class.forName("com.mysql.jdbc.Driver").newInstance();
    } catch (ClassNotFoundException ce) {
        out.println(ce);
    }

    String strFeature = request.getParameter("feature");
    String strRepo = request.getParameter("repo");
    String version = request.getParameter("version");
    String path = "";
    String name = "";
    String value = getValue(strFeature + strRepo);

    String url = searchHistory(value, version);

    if (url != null) {
        //do download
        foundCache = true;
        downloadUrl = "." + url;
    }

    if (!foundCache) {
        String[] feature = strFeature.split(",");
        String[] repo = strRepo.split(",");

        System.out.println("service is called by " + Thread.currentThread().getId());
        path = request.getServletContext().getRealPath("/build");
        name = request.getSession().getId();
        downloadUrl = "./download?id=" + name;
        //Step  1  create folder
        System.out.println("[Create folder]");
        Utils.createFolder(path, name);
        //Step 2 create pom
        System.out.println("[Copy pom]");
        Utils.copy(new File(path + "/pom.xml"), new File(path + "/" + name));
        System.out.println("[Modify pom]");
        Utils.updatePom(path + "/" + name + "/pom.xml", repo, true);
        //Step 3 create product file
        System.out.println("[Copy product]");
        Utils.copy(new File(path + "/eclipseplusplus.product"), new File(path + "/" + name));
        System.out.println("[Modify product]");
        Utils.updateProduct(path + "/" + name + "/eclipseplusplus.product", feature, true);
        //Step 4 copy install and modify
        System.out.println("[Create Install]");
        //Utils.copy(new File(path + "/install.bat"), new File(path + "/" + name));

        String nameScript = "";
        if (System.getProperty("os.name").startsWith("Windows")) {
            nameScript = "install.bat";
        } else if (System.getProperty("os.name").startsWith("Linux") || System.getProperty("os.name").startsWith("Mac")) {
            nameScript = "install.sh";
        }

        Utils.writeScript(path + "/" + name +"/" + nameScript, version);
    }
%>

<!DOCTYPE html>
<html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta name="description" content="">
        <meta name="author" content="">

        <title>Eclipse build platform</title>

        <!-- Bootstrap core CSS -->
        <link href="./css/bootstrap.css" rel="stylesheet">

        <!-- Custom styles for this template -->
        <link href="./css/jumbotron.css" rel="stylesheet">
        <script src="./js/jquery-1.10.2.min.js"></script>
        <script src="./js/bootstrap.min.js"></script>
        <script>
            $(document).ready(function() {
                var value = "<%=downloadUrl%>";
                $("#downloadbtn").attr("href", value);
                $("#downloadbtn").html("Download Your Eclipse!");
            });

        </script>

        <!-- Just for debugging purposes. Don't actually copy this line! -->
        <!--[if lt IE 9]><script src="../../docs-assets/js/ie8-responsive-file-warning.js"></script><![endif]-->

        <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
        <!--[if lt IE 9]>
          <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
          <script src="https://oss.maxcdn.com/libs/respond.js/1.3.0/respond.min.js"></script>
        <![endif]-->
    </head>

    <body style="">

        <!-- Main jumbotron for a primary marketing message or call to action -->
        <div class="jumbotron">
            <div class="container">
                <h1>Eclipse++ by ECE Paris & UPMC Lib6</h1>
                <p>Someone should write description here</p>
                <p><a id="downloadbtn" name="downloadbtn" class="btn btn-primary btn-lg" role="button">Building ...... </a></p>
            </div>
        </div>

        <div class="container">
            <!-- Example row of columns -->
            <div class="row">
                <%
                    if (!foundCache) {
                        Boolean hasError = false;
                        System.out.println("[Install]");
                        Runtime rt = Runtime.getRuntime();
                        Process pr;
                        String nameScript = "";
                        if (System.getProperty("os.name").startsWith("Windows")) {

                            nameScript = "install.bat";
                            pr = rt.exec(path + "/" + name + "/" + nameScript);

                            BufferedReader br = new BufferedReader(new InputStreamReader(
                                    pr.getInputStream()));

                            String line = null;
                            while ((line = br.readLine()) != null) {

                                System.out.println(line);
                                if (line.toLowerCase().contains("[error]")) {
                                    hasError = true;
                                }

                                out.println("<h5>" + line + "</h5>");
                                out.flush();
                            }

                            if (!hasError) {
                                insertHistory(name, value, version);
                            }

                        } else if (System.getProperty("os.name").startsWith("Linux") || System.getProperty("os.name").startsWith("Mac")) {
                            nameScript = "install.sh";
                            pr = rt.exec(path + "/" + name + "/" + nameScript);

                            BufferedReader br = new BufferedReader(new InputStreamReader(
                                    pr.getInputStream()));

                            String line = null;
                            while ((line = br.readLine()) != null) {

                                System.out.println(line);
                                if (line.toLowerCase().contains("error")) {
                                    hasError = true;
                                }

                                out.println("<h5>" + line + "</h5>");
                                out.flush();
                            }

                            if (!hasError) {
                                insertHistory(name, value, version);
                            }
                        }
                    }
                %>
            </div>

            <hr>

            <footer>
                <p>© Company 2013</p>
            </footer>
        </div> <!-- /container -->


        <!-- Bootstrap core JavaScript
        ================================================== -->
        <!-- Placed at the end of the document so the pages load faster -->



    </body>
</html>