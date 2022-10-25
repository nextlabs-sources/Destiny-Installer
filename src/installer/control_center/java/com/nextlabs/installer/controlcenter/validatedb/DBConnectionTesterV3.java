package com.nextlabs.installer.controlcenter.validatedb;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.security.KeyStore;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class DBConnectionTesterV3 {
	
	private static final String PASSWORD = "password";
	private static final String DB_ORACLE = "oracle";
	private static final String DB_SQL_SERVER = "sqlserver";
	private static final String DB_POSTGRE_SERVER = "postgresql";

	private static final String ORACLE_DRIVER = "oracle.jdbc.driver.OracleDriver";
	private static final String SQL_SERVER_DRIVER = "com.microsoft.sqlserver.jdbc.SQLServerDriver";
	private static final String POSTGRESQL_DRIVER = "org.postgresql.Driver";

	private String connectionUrl;
	private String username;
	private String password;
	private String driverClass;
	private String serverDn;

	public DBConnectionTesterV3(String[] args) 
			throws Exception {
		super();
		
		if(args == null || args.length < 3) {
			StringBuilder message = new StringBuilder();
			message.append("Usage ...");
			message.append("\nDBConnectionTesterV3 <connectionUrl> <username> <password> [<CA/server.cer>] [<server dn>]");
			
			System.out.println(message.toString());
		} else {
			if(args[0] == null || args[0].trim().length() <= 0) {
				System.out.println("Invalid connection url ...");
				System.exit(0);
			}
			
			if(args[1] == null || args[1].trim().length() <= 0) {
				System.out.println("Invalid username ...");
				System.exit(0);
			}
			
			if(args[2] == null || args[2].trim().length() <= 0) {
				System.out.println("Invalid password ...");
				System.exit(0);
			}
			
			this.connectionUrl = args[0].trim();
			this.username = args[1].trim();
			this.password = args[2].trim();
			
			if(args.length > 3 
					&& ((args[3] != null && args[3].trim().length() > 0))
					&& !args[3].equals("NA")) {
				cleanUp();
				setupTrustStore(args[3].trim());
			}
			
			if(args.length > 4 
					&& ((args[4] != null && args[4].trim().length() > 0))) {
				this.serverDn = args[4].trim();
			}
		}
		
		resolveDriverClass();
	}

	public void setupTrustStore(String certificate)
			throws Exception {
		KeyStore trustStore = KeyStore.getInstance(KeyStore.getDefaultType());
		trustStore.load(null, PASSWORD.toCharArray());
		
		try (FileInputStream fis = new FileInputStream(certificate); BufferedInputStream bis = new BufferedInputStream(fis)) {
			CertificateFactory certFactory = CertificateFactory.getInstance("X.509");
			Certificate cert = null;
			
			while (bis.available() > 0) {
				cert = certFactory.generateCertificate(bis);
				trustStore.setCertificateEntry("database", cert);
			}
		} catch(Exception err) {
			throw err;
		}
		
		try (FileOutputStream fos = new FileOutputStream("tmp-db-truststore.jks")) {
			trustStore.store(fos, PASSWORD.toCharArray());
		} catch(Exception err) {
			throw err;
		}
		
		System.setProperty("javax.net.ssl.trustStore", "tmp-db-truststore.jks");
		System.setProperty("javax.net.ssl.trustStorePassword", "password");
		System.setProperty("javax.net.ssl.trustStoreType", "JKS");
	}

	public Connection getConnection() 
			throws Exception {
		try {
			if(serverDn != null && serverDn.length() > 0) {
				if(ORACLE_DRIVER.equals(driverClass)) {
					System.setProperty("oracle.net.ssl_server_dn_match", "true");
				} else if(SQL_SERVER_DRIVER.equals(driverClass)) {
					connectionUrl += ";trustStore=" + new File("tmp-db-truststore.jks").getAbsolutePath();
					connectionUrl += ";trustStorePassword=password";
				}
			}
			
			try {
				Class.forName(driverClass);
			} catch(ClassNotFoundException err) {
				err.printStackTrace();
				throw err;
			}
			
			return DriverManager.getConnection("jdbc:" + connectionUrl, username, password);
		} catch(Exception err) {
			throw err;
		}
	}
	
	public boolean testConnection()
			throws Exception {
		Connection connection = null;
		Statement statement = null;
		
		try {
			connection = getConnection();
			statement = connection.createStatement();
			statement.executeUpdate("create table test_connection_141286 (id int, name varchar(30))");
			statement.executeUpdate("insert into test_connection_141286 (id,name ) values (1, 'nameValue')");
			statement.executeUpdate("drop table test_connection_141286");

			statement.close();
		} catch(Exception err) {
			throw err;
		} finally {
			if(connection != null) {
				try {
					connection.close();
				} catch(SQLException sqlErr) {
					// Ignore
				}
			}
		}
		
		return true;
	}

	public void cleanUp() {
		try {
			File file = new File("tmp-db-truststore.jks");
			
			if(file.exists()) {
				file.delete();
			}
		} catch(Exception err) {
			// Ignore
		}
	}
	
	private void resolveDriverClass()
			throws Exception {
		if (connectionUrl.startsWith(DB_ORACLE)) {
			driverClass = ORACLE_DRIVER;
		} else if (connectionUrl.startsWith(DB_SQL_SERVER)) {
			driverClass = SQL_SERVER_DRIVER;
		} else if (connectionUrl.startsWith(DB_POSTGRE_SERVER)) {
			driverClass = POSTGRESQL_DRIVER;
		} else {
			throw new IllegalArgumentException("Unsupported prefix in connect string: " + connectionUrl);
		}
	}

	public static void main(String[] args) {
		try {
			DBConnectionTesterV3 dbTester = new DBConnectionTesterV3(args);
			System.out.println(dbTester.testConnection());
			dbTester.cleanUp();
		} catch(Exception err) {
			System.out.println(err.getMessage());
		}
	}
}
