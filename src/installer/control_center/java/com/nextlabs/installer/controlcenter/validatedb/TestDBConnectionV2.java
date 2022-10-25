package com.nextlabs.installer.controlcenter.validatedb;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * TestDBConnection to check DB connection for ORALCE, SQL Server, PostgreSQL
 *
 * @author : Amila Silva
 */
public class TestDBConnectionV2 {

  // attempt to get a connection to the data source using the given
  // driver, url, user, and password
  public static boolean checkConnection(String connectString, String user,
      String pwd) throws Exception {

    // System.out.println(" Driver: " + connectString);
    ConnectionInfo connInfo = new ConnectionInfo(connectString, user, pwd);
    return connInfo.testConnectionAndPrivillages();
  }

  public static class ConnectionInfo {

    private String url;
    private String userName;
    private String passWord;
    private String dbType;
    private String driverClass;

    private static final String DB_ORACLE = "oracle";
    private static final String DB_SQL_SERVER = "sqlserver";
    private static final String DB_POSTGRE_SERVER = "postgresql";

    private static final String ORACLE_DRIVER = "oracle.jdbc.driver.OracleDriver";
    private static final String SQL_SERVER_DRIVER = "com.microsoft.sqlserver.jdbc.SQLServerDriver";
    private static final String POSTGRESQL_DRIVER = "org.postgresql.Driver";

    public ConnectionInfo(String connectStr, String uName, String pw) {
      userName = uName;
      passWord = pw;
      setDBType(connectStr);
    }

    // sqlserver://localhost:1433;DatabaseName=<db name>;
    // oracle:thin:@localhost:1521:orcl
    // postgresql://localhost:5432/cc76
    private void setDBType(String connectStr) {
      if (connectStr == null) {
        throw new IllegalArgumentException(
            "Connection String cannot be null");
      }
      String lowerConnectStr = connectStr.toLowerCase();
      if (lowerConnectStr.startsWith(ConnectionInfo.DB_ORACLE)) {
        dbType = ConnectionInfo.DB_ORACLE;
        driverClass = ConnectionInfo.ORACLE_DRIVER;

      } else if (lowerConnectStr.startsWith(ConnectionInfo.DB_SQL_SERVER)) {
        dbType = ConnectionInfo.DB_SQL_SERVER;
        driverClass = ConnectionInfo.SQL_SERVER_DRIVER;
      } else if (lowerConnectStr
          .startsWith(ConnectionInfo.DB_POSTGRE_SERVER)) {
        dbType = ConnectionInfo.DB_POSTGRE_SERVER;
        driverClass = ConnectionInfo.POSTGRESQL_DRIVER;
      } else {
        throw new IllegalArgumentException(
            "Unsupported prefix in connect string: " + connectStr);
      }
      this.url = "jdbc:" + connectStr;
    }

    public boolean testConnectionAndPrivillages() throws Exception {
      Connection connection = null;
      boolean bConnected = false;
      try {
        Class.forName(driverClass);
        connection = DriverManager.getConnection(url, userName,
            passWord);
        checkPrivillages(connection);

        bConnected = true;
      } catch (Exception ex) {
        throw new Exception(ex.getMessage());
      } finally {
        if (connection != null) {
          try {
            connection.close();
          } catch (SQLException se) {
          }
          connection = null;
        }
      }
      return bConnected;
    }

    public boolean checkPrivillages(Connection connection) throws Exception {
      Statement st = null;
      try {
        st = connection.createStatement();
        st.executeUpdate("create table test_connection_141286 (id int, name varchar(30))");
        st.executeUpdate("insert into test_connection_141286 (id,name ) values (1, 'nameValue')");
        st.executeUpdate("drop table test_connection_141286");

        return true;
      } catch (SQLException ex) {

        throw new Exception(ex.getMessage());
      } finally {
        if (st != null)
          st.close();
      }
    }
  }

  public static void main(String[] args) {
    try {
      if (args == null || args.length < 3) {
        System.out.println("Usage....");
      } else {
        String url = args[0];
        String user = args[1];
        String pwd = args[2];
        boolean connectionOk = TestDBConnectionV2.checkConnection(url, user, pwd);
        System.out.println("" + connectionOk);
      }

    } catch (Exception e) {
      System.out.println(e.getMessage());
    }
  }
}
