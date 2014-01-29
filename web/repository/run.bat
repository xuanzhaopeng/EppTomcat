%~d0
cd %~dp0
java -Declipse.ignoreApp=true -Dosgi.noShutdown=true -Dserver.home=. -Dbundles.configuration.location=./configuration -Dlogback.configurationFile=./configuration/logbackConfiguration.xml -jar equinox.jar -console