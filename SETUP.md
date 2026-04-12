Set up a Maven project called "jotpage" in the current directory for Java 17, Apache Tomcat 10 (Jakarta Servlet 6.0), with the following structure:

pom.xml — groupId: com.jotpage, artifactId: jotpage, packaging: war. Dependencies:
- jakarta.servlet-api 6.0.0 (provided)
- mysql-connector-j 8.3.0
- gson 2.11.0
- google-api-client 2.7.0
- google-oauth-client-jetty 1.36.0
- google-api-services-oauth2 v2-rev20200213-2.0.0
- jstl-api 3.0.0 + jakarta.servlet.jsp.jstl (glassfish impl) 3.0.1

Plugins: maven-compiler-plugin (Java 17), maven-war-plugin 3.4.0.

Create these empty directories:
- src/main/java/com/jotpage/servlet
- src/main/java/com/jotpage/model
- src/main/java/com/jotpage/dao
- src/main/java/com/jotpage/util
- src/main/webapp/WEB-INF
- src/main/webapp/css
- src/main/webapp/js
- src/main/webapp/jsp

Create src/main/webapp/WEB-INF/web.xml — minimal Jakarta Servlet 6.0 descriptor with display-name "JotPage".

Create src/main/java/com/jotpage/util/DbUtil.java — a simple JDBC connection utility class that reads DB url/user/pass from context.xml JNDI resource named "jdbc/jotpage".

Create src/main/webapp/META-INF/context.xml with a JNDI DataSource resource for MySQL (host=localhost, db=jotpage, user=jotpage, password=CHANGEME).

Create src/main/webapp/index.jsp — a bare-bones "JotPage" landing page that includes Bootstrap 5 CDN and has a "Sign in with Google" button placeholder.

Do NOT create any Spring files. This is a plain servlet project.