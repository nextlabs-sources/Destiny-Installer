package com.nextlabs.installer.controlcenter.confighelper;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.math.BigInteger;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.AbstractMap;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Properties;
import java.util.Set;
import java.util.function.Function;

import org.w3c.dom.Document;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import com.bluejungle.framework.crypt.ReversibleEncryptor;
import com.bluejungle.framework.utils.StringUtils;

/**
 * A helper to migrate configurations stored in files to database configuration table.
 *
 * @author Sachindra Dasun
 */
public class ConfigHelper {

    private final static String SELECT_CONFIG_QUERY = "SELECT VALUE_FORMAT FROM SYS_CONFIG WHERE APPLICATION = ? AND CONFIG_KEY = ?";
    private final static String UPDATE_QUERY = "UPDATE SYS_CONFIG SET VALUE = ?, DEFAULT_VALUE = ? WHERE APPLICATION = ? AND CONFIG_KEY = ?";
    private final static String VERIFY_QUERY = "SELECT VALUE, VALUE_FORMAT FROM SYS_CONFIG WHERE APPLICATION = ? AND CONFIG_KEY = ?";
    private final static String IMPORTANT_CONFIGURATIONS_QUERY = "SELECT APPLICATION, CONFIG_KEY, VALUE FROM SYS_CONFIG WHERE APPLICATION = ? AND CONFIG_KEY IN (?, ?)";

    private final static String APPLICATION = "application";
    private final static String APPLICATION_CONFIG_SERVICE = "config-service";
    private final static String APPLICATION_CONSOLE = "console";
    private final static String APPLICATION_ADMINISTRATOR = "administrator";
    private final static String APPLICATION_REPORTER = "reporter";
    private final static String APPLICATION_CAS = "cas";
    private final static String APPLICATION_DMS = "dms";

    private final static String CONFIG_FILE_NAME_BOOTSTRAP = "bootstrap.properties";
    private final static String CONFIG_FILE_NAME_CONSOLE = "cc-console-app.properties";
    private final static String CONFIG_FILE_NAME_CAS = "cas.properties";
    private final static String CONFIG_FILE_NAME_ADMINISTRATOR = "mgmt_context_param.properties";
    private final static String CONFIG_FILE_NAME_REPORTER = "reporter_context_param.properties";
    private final static String CONFIG_FILE_NAME_CONFIGURATION_XML = "configuration.xml";
    
    private final static Map<String, Set<String>> EXCLUDE_KEYS = new HashMap<>();
    private final static Map<String, Function<String, String>> VALUE_TRANSFORMATIONS = new HashMap<>();
    
    private final static Map<String, String> KEY_MAPPINGS_BOOTSTRAP = new HashMap<>();
    private final static Map<String, String> KEY_MAPPINGS_CONSOLE = new HashMap<>();
    private final static Map<String, String> KEY_MAPPINGS_ADMINISTRATOR = new HashMap<>();
    private final static Map<String, String> KEY_MAPPINGS_REPORTER = new HashMap<>();
    private final static Map<String, String> KEY_MAPPINGS_CAS = new HashMap<>();
    private final static Map<String, String> KEY_MAPPINGS_CONFIGURATION_XML_EMAIL = new HashMap<>();
    private final static Map<String, String> KEY_MAPPINGS_CONFIGURATION_XML_KEYSTORE = new HashMap<>();
    private final static Map<String, String> KEY_MAPPINGS_CONFIGURATION_XML = new HashMap<>();

    private final static Map<String, CombiningMapping> COMBINING_KEY_MAPPINGS_CONFIGURATION_XML = new HashMap<>();
    
    private static class CombiningMapping {
        private String path;
        private String separator;

        public static CombiningMapping build(String path, String separator) {
            return new CombiningMapping(path, separator);
        }

        private CombiningMapping(String path, String separator) {
            this.path = path;
            this.separator = separator;
        }
        
        public String getSeparator() {
            return separator;
        }

        public String getPath() {
            return path;
        }
    }
    
    private final static Map<String, AbstractMap.SimpleEntry<String, String>> VALUE_MODIFIERS_CONSOLE = new HashMap<>();

    private static String dbDriver;
    private static String dbUrl;
    private static String dbUsername;
    private static String dbEncryptedPassword;
    private static String configDir;

    private static ReversibleEncryptor reversibleEncryptor = new ReversibleEncryptor();

    public static void main(String[] args) {
        dbDriver = System.getProperty("db.driver");
        dbUrl = System.getProperty("db.url");
        dbUsername = System.getProperty("db.username");
        dbEncryptedPassword = System.getProperty("db.password");
        configDir = System.getProperty("config.dir");
        
        // Exclude keys are the field that appear in the properties file but we do not want to process
        initExcludeKeys();
        
        // Key mappings are used to handle differences between keys in the configuration file and the database table
        initKeyMappings();

        // Value modifiers are used to convert old values into new values by replacing a part of the value
        initValueModifiers();
        
        // Value transformation to change from old data to new expected data. E.g. 0 to false, 1 to true
        // Same config key should have the same expected data regardless of application scope
        initValueTransformers();
        
        migrateKeyStoreConfigurations();
        migrateConsoleConfigurations();
        migrateCasConfigurations();
        migrateAdministratorConfigurations();
        migrateReporterConfigurations();
        migrateEmailConfigurations();
        migrateConfigurationXml();

        // The parameters obtained during the installation can be passed as system parameters to store in
        // database table. Parameter key should start with cc_<application name> (e.g.: cc_console)
        addInstallerProvidedConfigurations();

        // Copy some configurations from bootstrap configuration file to database.
        updateBootstrapConfigurations();

        // Generate and update random password for ActiveMQ
        updateActiveMQPassword();

        createConfigOverridesSample();
    }

    private static void createConfigOverridesSample() {
        try (Connection connection = DriverManager.getConnection(dbUrl, dbUsername,
                reversibleEncryptor.decrypt(dbEncryptedPassword))) {
            try (PreparedStatement statement = connection.prepareStatement(IMPORTANT_CONFIGURATIONS_QUERY)) {
                try (FileWriter fileWriter = new FileWriter(String.format("%s/%s", configDir, "config-overrides-sample.properties"))) {
                    statement.setString(1, "application");
                    statement.setString(2, "server.name");
                    statement.setString(3, "web.service.server.name");
                    try (ResultSet rs = statement.executeQuery()) {
                        while (rs.next()) {
                            fileWriter.write(String.format("#%s.%s=%s", rs.getString("APPLICATION"),
                                    rs.getString("CONFIG_KEY"), rs.getString("VALUE")));
                            fileWriter.write(System.lineSeparator());
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.out.println("Error in creating configuration overrides sample file");
            e.printStackTrace();
        }
    }

    private static void addInstallerProvidedConfigurations() {
        try {
            Map<String, String> applicationConfigurations = new HashMap<>();
            Map<String, String> consoleConfigurations = new HashMap<>();
            Map<String, String> dmsConfigurations = new HashMap<>();
            Map<String, String> configServiceConfigurations = new HashMap<>();
            for (String key : System.getProperties().stringPropertyNames()) {
                if (key.startsWith("app_" + APPLICATION)) {
                    String value = System.getProperty(key);
                    key = key.substring(key.indexOf(".") + 1);
                    if (value != null && !value.isEmpty()) {
                        applicationConfigurations.put(key, value);
                    }
                } else if (key.startsWith("app_" + APPLICATION_CONSOLE)) {
                    String value = System.getProperty(key);
                    key = key.substring(key.indexOf(".") + 1);
                    if (value != null && !value.isEmpty()) {
                        consoleConfigurations.put(key, value);
                    }
                } else if (key.startsWith("app_" + APPLICATION_DMS)) {
                    String value = System.getProperty(key);
                    key = key.substring(key.indexOf(".") + 1);
                    if (value != null && !value.isEmpty()) {
                        dmsConfigurations.put(key, value);
                    }
                } else if (key.startsWith("app_" + APPLICATION_CONFIG_SERVICE)) {
                    String value = System.getProperty(key);
                    key = key.substring(key.indexOf(".") + 1);
                    if (value != null && !value.isEmpty()) {
                        configServiceConfigurations.put(key, value);
                    }
                }
            }
            saveToDb(APPLICATION, applicationConfigurations);
            saveToDb(APPLICATION_CONSOLE, consoleConfigurations);
            saveToDb(APPLICATION_DMS, dmsConfigurations);
            saveToDb(APPLICATION_CONFIG_SERVICE, configServiceConfigurations);
        } catch (Exception e) {
            System.out.println("Error in adding installer provided configurations");
            e.printStackTrace();
        }
    }

    private static void initValueModifiers() {
        VALUE_MODIFIERS_CONSOLE.put("app.service.security",
                new AbstractMap.SimpleEntry<>("j_spring_cas_security_check", "login/cas"));
    }

    /**
     * List of keys to skip, based on application type.
     * Upon reading from the source, these keys will be skipped and not putting into the configuration map
     * These are the source (original) key
     */
    private static void initExcludeKeys() {
    	Set<String> CONSOLE_KEYS = new HashSet<>();
    	CONSOLE_KEYS.add("app.service.home");
    	CONSOLE_KEYS.add("app.service.security");
    	CONSOLE_KEYS.add("cas.service.login");
    	CONSOLE_KEYS.add("cas.service.logout");
    	CONSOLE_KEYS.add("cas.service.url");
    	CONSOLE_KEYS.add("help.content.dir.path");
    	
    	EXCLUDE_KEYS.put(APPLICATION_CONSOLE, CONSOLE_KEYS);
    }
    
    /**
     * For the same key, regardless of application type, the data type should be same
     */
    private static void initValueTransformers() {
    	VALUE_TRANSFORMATIONS.put("dac.sync.delete.after.sync", 
    			value -> "false".equalsIgnoreCase(value) ? "false" : "true");
    	
    	VALUE_TRANSFORMATIONS.put("reporter.show.sharepoint", 
    			value -> "0".equals(value) ? "false" : "true");
    }
    
    /**
     * Used to map configuration file keys to database table keys. Null value keys will not be stored in the database
     * table.
     */
    private static void initKeyMappings() {

        KEY_MAPPINGS_BOOTSTRAP.put("spring.cloud.config.username", "config.client.username");
        KEY_MAPPINGS_BOOTSTRAP.put("spring.cloud.config.password", "config.client.password");
        KEY_MAPPINGS_BOOTSTRAP.put("spring.cloud.config.uri", null);
        KEY_MAPPINGS_BOOTSTRAP.put("spring.cloud.config.fail-fast", null);

        KEY_MAPPINGS_CONSOLE.put("application.version", null);
        KEY_MAPPINGS_CONSOLE.put("db.driver", null);
        KEY_MAPPINGS_CONSOLE.put("db.hibernate.ddl.auto", null);
        KEY_MAPPINGS_CONSOLE.put("db.hibernate.dialect", null);
        KEY_MAPPINGS_CONSOLE.put("db.max.poolsize", "db.comboPooledDataSource.maxPoolSize");
        KEY_MAPPINGS_CONSOLE.put("db.password", null);
        KEY_MAPPINGS_CONSOLE.put("db.url", null);
        KEY_MAPPINGS_CONSOLE.put("db.username", null);
        KEY_MAPPINGS_CONSOLE.put("data.transportation.keystore.file", "data.transportation.keyStoreFile");
        KEY_MAPPINGS_CONSOLE.put("data.transportation.allow.plain.text.export", "data.transportation.allowPlainTextExport");
        KEY_MAPPINGS_CONSOLE.put("data.transportation.allow.plain.text.import", "data.transportation.allowPlainTextImport");
        KEY_MAPPINGS_CONSOLE.put("data.transportation.shared.key", "data.transportation.sharedKey");
        
        KEY_MAPPINGS_ADMINISTRATOR.put("ComponentName", "component.name");
        KEY_MAPPINGS_ADMINISTRATOR.put("DMSLocation", "dms.location");
        KEY_MAPPINGS_ADMINISTRATOR.put("InstallHome", "install.home");
        KEY_MAPPINGS_ADMINISTRATOR.put("Location", "location");

        KEY_MAPPINGS_REPORTER.put("ComponentName", "component.name");
        KEY_MAPPINGS_REPORTER.put("DACLocation", "dac.location");
        KEY_MAPPINGS_REPORTER.put("DMSLocation", "dms.location");
        KEY_MAPPINGS_REPORTER.put("InstallHome", "install.home");
        KEY_MAPPINGS_REPORTER.put("Location", "location");

        KEY_MAPPINGS_CAS.put("database.pool.minSize", "db.comboPooledDataSource.minPoolSize");
        KEY_MAPPINGS_CAS.put("database.pool.maxSize", "db.comboPooledDataSource.maxPoolSize");
        KEY_MAPPINGS_CAS.put("database.pool.maxIdleTime", "db.comboPooledDataSource.maxIdleTime");
        KEY_MAPPINGS_CAS.put("database.pool.acquireIncrement", "db.comboPooledDataSource.acquireIncrement");
        KEY_MAPPINGS_CAS.put("database.pool.idleConnectionTestPeriod", "db.comboPooledDataSource.idleConnectionTestPeriod");
        KEY_MAPPINGS_CAS.put("database.pool.acquireRetryAttempts", "db.comboPooledDataSource.acquireRetryAttempts");
        KEY_MAPPINGS_CAS.put("database.pool.acquireRetryDelay", "db.comboPooledDataSource.acquireRetryDelay");
        KEY_MAPPINGS_CAS.put("ldaps.keyStore.file", "ldaps.keyStoreFile");
        KEY_MAPPINGS_CAS.put("ldaps.trustStore.file", "ldaps.trustStoreFile");
        KEY_MAPPINGS_CAS.put("failed.login.attempts", "failed.login.attempts");

        KEY_MAPPINGS_CONFIGURATION_XML_EMAIL.put("spring.mail.host", "/DestinyConfiguration/MessageHandlers/MessageHandler/Properties/Property[1]/Value/text()");
        KEY_MAPPINGS_CONFIGURATION_XML_EMAIL.put("spring.mail.port", "/DestinyConfiguration/MessageHandlers/MessageHandler/Properties/Property[2]/Value/text()");
        KEY_MAPPINGS_CONFIGURATION_XML_EMAIL.put("spring.mail.username", "/DestinyConfiguration/MessageHandlers/MessageHandler/Properties/Property[3]/Value/text()");
        KEY_MAPPINGS_CONFIGURATION_XML_EMAIL.put("spring.mail.password", "/DestinyConfiguration/MessageHandlers/MessageHandler/Properties/Property[4]/Value/text()");
        KEY_MAPPINGS_CONFIGURATION_XML_EMAIL.put("spring.mail.properties.mail.smtp.from", "/DestinyConfiguration/MessageHandlers/MessageHandler/Properties/Property[5]/Value/text()");
        KEY_MAPPINGS_CONFIGURATION_XML_EMAIL.put("cc.mail.default.to", "/DestinyConfiguration/MessageHandlers/MessageHandler/Properties/Property[6]/Value/text()");

        KEY_MAPPINGS_CONFIGURATION_XML.put("dms.db.dialect", "/DestinyConfiguration/GenericComponents/GenericComponent[1]/Properties/Property[2]/Value/text()");

        KEY_MAPPINGS_CONFIGURATION_XML.put("dabs.log.thread.count", "/DestinyConfiguration/DABS/FileSystemLogConfiguration/ThreadPoolMaximumSize/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("dabs.log.upload.size", "/DestinyConfiguration/DABS/FileSystemLogConfiguration/QueueManagerUploadSize/text()");
        
        KEY_MAPPINGS_CONFIGURATION_XML.put("dac.number.of.extended.attributes", "/DestinyConfiguration/DAC/Properties/Property[1]/Value/text()");
        
        KEY_MAPPINGS_CONFIGURATION_XML.put("dac.sync.time.of.day", "/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/SyncOperation/TimeOfDay/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("dac.sync.time.interval", "/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/SyncOperation/TimeInterval/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("dac.sync.timeout.minutes", "/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/SyncOperation/TimeoutInMinutes/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("dac.sync.delete.after.sync", "/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/SyncOperation/DeleteAfterSync/text()");
        
        KEY_MAPPINGS_CONFIGURATION_XML.put("dac.index.rebuild.time.of.day", "/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/IndexesRebuildOperation/TimeOfDay/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("dac.index.rebuild.auto.rebuild", "/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/IndexesRebuildOperation/AutoRebuildIndexes/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("dac.index.rebuild.timeout.minutes", "/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/IndexesRebuildOperation/TimeoutInMinutes/text()");
        
        KEY_MAPPINGS_CONFIGURATION_XML.put("dac.archive.time.of.day", "/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/ArchiveOperation/TimeOfDay/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("dac.archive.days.to.keep", "/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/ArchiveOperation/DaysOfDataToKeep/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("dac.archive.auto.archive", "/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/ArchiveOperation/AutoArchive/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("dac.archive.timeout.minutes", "/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/ArchiveOperation/TimeoutInMinutes/text()");
        
        KEY_MAPPINGS_CONFIGURATION_XML.put("reporter.use.past.data.for.monitoring", "/DestinyConfiguration/Reporter/Properties/Property[1]/Value/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("reporter.monitor.execution.interval", "/DestinyConfiguration/Reporter/Properties/Property[2]/Value/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("reporter.show.sharepoint", "/DestinyConfiguration/Reporter/ShowSharePointReports/text()");
        
        KEY_MAPPINGS_CONFIGURATION_XML.put("repositories.management.hibernate.dialect", "/DestinyConfiguration/Repositories/Repository[1]/Properties/Property[1]/Value/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("repositories.activity.hibernate.dialect", "/DestinyConfiguration/Repositories/Repository[2]/Properties/Property[1]/Value/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("repositories.pf.hibernate.dialect", "/DestinyConfiguration/Repositories/Repository[3]/Properties/Property[1]/Value/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("repositories.dictionary.hibernate.dialect", "/DestinyConfiguration/Repositories/Repository[4]/Properties/Property[1]/Value/text()");

        KEY_MAPPINGS_CONFIGURATION_XML.put("repositories.pf.connection.maxpoolsize", "/DestinyConfiguration/Repositories/ConnectionPools/ConnectionPool[1]/MaxPoolSize/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("repositories.dictionary.connection.maxpoolsize", "/DestinyConfiguration/Repositories/ConnectionPools/ConnectionPool[2]/MaxPoolSize/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("repositories.activity.connection.maxpoolsize", "/DestinyConfiguration/Repositories/ConnectionPools/ConnectionPool[3]/MaxPoolSize/text()");
        KEY_MAPPINGS_CONFIGURATION_XML.put("repositories.management.connection.maxpoolsize", "/DestinyConfiguration/Repositories/ConnectionPools/ConnectionPool[4]/MaxPoolSize/text()");
        

        KEY_MAPPINGS_CONFIGURATION_XML_KEYSTORE.put("key.store.password", "/DestinyConfiguration/GenericComponents/GenericComponent[1]/Properties/Property[1]/Value/text()");
        KEY_MAPPINGS_CONFIGURATION_XML_KEYSTORE.put("trust.store.password", "/DestinyConfiguration/GenericComponents/GenericComponent[1]/Properties/Property[1]/Value/text()");

        // This is for mappings that are multiple elements in older
        // configuration.xml files, but are combined into single
        // elements in the config code
        COMBINING_KEY_MAPPINGS_CONFIGURATION_XML.put("dabs.trusted.domains", CombiningMapping.build("/DestinyConfiguration/DABS/TrustedDomainsConfiguration/MutuallyTrusted", ";"));
        COMBINING_KEY_MAPPINGS_CONFIGURATION_XML.put("dac.index.rebuild.days.of.week", CombiningMapping.build("/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/IndexesRebuildOperation/DaysOfWeek/DayOfWeek", ","));
        COMBINING_KEY_MAPPINGS_CONFIGURATION_XML.put("dac.index.rebuild.days.of.month", CombiningMapping.build("/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/IndexesRebuildOperation/DaysOfMonth/DayOfMonth", ","));
        COMBINING_KEY_MAPPINGS_CONFIGURATION_XML.put("dac.archive.rebuild.days.of.week", CombiningMapping.build("/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/ArchiveOperation/DaysOfWeek/DayOfWeek", ","));
        COMBINING_KEY_MAPPINGS_CONFIGURATION_XML.put("dac.archive.rebuild.days.of.month", CombiningMapping.build("/DestinyConfiguration/DAC/ActivityJournalSettingConfiguration/ArchiveOperation/DaysOfMonth/DayOfMonth", ","));
    }

    private static void migrateConsoleConfigurations() {
        // First read configurations from the file and save to the database configuration table
        // Then move the configuration file to a backup folder
        try {
            Map<String, String> existingConfigurations = getConfigsFromPropertiesFile(APPLICATION_CONSOLE, CONFIG_FILE_NAME_CONSOLE);
            applyValueModifiers(APPLICATION_CONSOLE, existingConfigurations);
            boolean configurationsFound = saveToDb(APPLICATION_CONSOLE, existingConfigurations);
            if (configurationsFound) {
                moveFileToBackup(CONFIG_FILE_NAME_CONSOLE);
            }
        } catch (Exception e) {
            System.out.println("Error in migrating console configurations");
            e.printStackTrace();
        }
    }

    private static void migrateCasConfigurations() {
        // First read configurations from the file and save to the database configuration table
        // Then move the configuration file to a backup folder
        try {
            Map<String, String> existingConfigurations = getConfigsFromPropertiesFile(APPLICATION_CAS, CONFIG_FILE_NAME_CAS);
            applyValueModifiers(APPLICATION_CAS, existingConfigurations);
            boolean configurationsFound = saveToDb(APPLICATION_CAS, existingConfigurations);
            if (configurationsFound) {
                moveFileToBackup(CONFIG_FILE_NAME_CAS);
            }
        } catch (Exception e) {
            System.out.println("Error in migrating cas configurations");
            e.printStackTrace();
        }
    }

    private static void applyValueModifiers(String application, Map<String, String> configurations) {
        switch (application) {
            case APPLICATION_CONSOLE: {
                for (Map.Entry<String, String> entry : configurations.entrySet()) {
                    if (VALUE_MODIFIERS_CONSOLE.containsKey(entry.getKey())) {
                        AbstractMap.Entry<String, String> replacement = VALUE_MODIFIERS_CONSOLE.get(entry.getKey());
                        String value = entry.getValue().replace(replacement.getKey(), replacement.getValue());
                        entry.setValue(value);
                    }
                }
                break;
            }
        }
    }

    private static void migrateKeyStoreConfigurations() {
        // Read configurations from the configuration.xml file and save to the database configuration table.
        // Skip this migration process if configuration.xml no longer exist
        try {
            saveToDb(APPLICATION, getConfigsFromXmlFile(CONFIG_FILE_NAME_CONFIGURATION_XML, KEY_MAPPINGS_CONFIGURATION_XML_KEYSTORE));
        } catch (Exception e) {
            System.out.println("Error in migrating key store configurations");
            e.printStackTrace();
        }
    }

    private static void migrateAdministratorConfigurations() {
        // First read configurations from the file and save to the database configuration table
        // Then move the configuration file to a backup folder
        try {
            boolean configurationsFound = saveToDb(APPLICATION_ADMINISTRATOR,
                    getConfigsFromPropertiesFile(APPLICATION_ADMINISTRATOR, CONFIG_FILE_NAME_ADMINISTRATOR));
            if (configurationsFound) {
                moveFileToBackup(CONFIG_FILE_NAME_ADMINISTRATOR);
            }
        } catch (Exception e) {
            System.out.println("Error in migrating administrator configurations");
            e.printStackTrace();
        }
    }

    private static void migrateReporterConfigurations() {
        // First read configurations from the file and save to the database configuration table
        // Then move the configuration file to a backup folder
        try {
            boolean configurationsFound = saveToDb(APPLICATION_REPORTER,
                    getConfigsFromPropertiesFile(APPLICATION_REPORTER, CONFIG_FILE_NAME_REPORTER));
            if (configurationsFound) {
                moveFileToBackup(CONFIG_FILE_NAME_REPORTER);
            }
        } catch (Exception e) {
            System.out.println("Error in migrating reporter configurations");
            e.printStackTrace();
        }
    }

    private static void migrateEmailConfigurations() {
        // Read configurations from the file and save to the database configuration table.
        // Do not move the configuration file to a backup folder as the file still has other configurations to read.
        try {
            saveToDb(APPLICATION, getConfigsFromXmlFile(CONFIG_FILE_NAME_CONFIGURATION_XML, KEY_MAPPINGS_CONFIGURATION_XML_EMAIL));
        } catch (Exception e) {
            System.out.println("Error in migrating E-Mail configurations");
            e.printStackTrace();
        }
    }

    private static void migrateConfigurationXml() {
        // First read configurations from the file and save to the database configuration table
        // Then move the configuration file to a backup folder
        try {
            boolean configurationsFound = saveToDb(APPLICATION_DMS,
                                                   getConfigsFromXmlFile(CONFIG_FILE_NAME_CONFIGURATION_XML, KEY_MAPPINGS_CONFIGURATION_XML));

            configurationsFound |= saveToDb(APPLICATION_DMS,
                                            getCombiningConfigsFromXmlFile(CONFIG_FILE_NAME_CONFIGURATION_XML, COMBINING_KEY_MAPPINGS_CONFIGURATION_XML));
                 
            if (configurationsFound) {
                moveFileToBackup(CONFIG_FILE_NAME_CONFIGURATION_XML);
            }
        } catch (Exception e) {
            System.out.println("Error in migrating configuration.xml configurations");
            e.printStackTrace();
        }
    }

    private static void updateBootstrapConfigurations() {
        try {
            saveToDb(APPLICATION_CONFIG_SERVICE,
                    getConfigsFromPropertiesFile(APPLICATION_CONFIG_SERVICE, CONFIG_FILE_NAME_BOOTSTRAP));
        } catch (Exception e) {
            System.out.println("Error in updating bootstrap configurations");
            e.printStackTrace();
        }
    }

    private static void updateActiveMQPassword() {
        try {
            String password = generateRandomPassword();
            Map<String, String> configServiceConfigurations = new HashMap<>();
            configServiceConfigurations.put("activemq.broker.password", password);
            saveToDb(APPLICATION_CONFIG_SERVICE, configServiceConfigurations);

            Map<String, String> applicationConfigurations = new HashMap<>();
            applicationConfigurations.put("config.activeMQConnectionFactory.password", password);
            saveToDb(APPLICATION, applicationConfigurations);
        } catch (Exception e) {
            System.out.println("Error in updating ActiveMQ password configurations");
            e.printStackTrace();
        }
    }

    private static boolean saveToDb(String application, Map<String, String> configurations) throws Exception {
        if (configurations.isEmpty()) {
            return false;
        }
        Class.forName(dbDriver);
        try (Connection connection = DriverManager.getConnection(dbUrl, dbUsername,
                reversibleEncryptor.decrypt(dbEncryptedPassword))) {
            connection.setAutoCommit(false);
            try (PreparedStatement statement = connection.prepareStatement(UPDATE_QUERY)) {
                for (Map.Entry<String, String> entry : configurations.entrySet()) {
                    String key = getMappedKey(application, entry.getKey());
                    if (key != null) {
                        String valueFormat = null;
                        try (PreparedStatement valuePatternStatement = connection.prepareStatement(SELECT_CONFIG_QUERY)) {
                            valuePatternStatement.setString(1, application);
                            valuePatternStatement.setString(2, key);
                            try (ResultSet rs = valuePatternStatement.executeQuery()) {
                                if (rs.next()) {
                                    valueFormat = rs.getString("VALUE_FORMAT");
                                }
                            }
                        }
                        
                        String value = transformValue(entry, valueFormat);
                        statement.setString(1, value);
                        statement.setString(2, value);
                        statement.setString(3, application);
                        statement.setString(4, key);
                        statement.addBatch();
                    }
                }
                statement.executeBatch();
                connection.commit();
                System.out.println(String.format("Saved %d configurations for %s to database table",
                        configurations.size(), application));
                boolean verified = verifySavedConfigurations(connection, application, configurations);
                if (verified) {
                    System.out.println(String.format("Verified %s configurations saved in the database table",
                            application));
                } else {
                    System.out.println("Some configurations were not stored in the database. Please refer to the log" +
                            " for property names");
                }
            }
        }
        return true;
    }
    
    /**
     * Transform value from original form to expected form
     * If data type transformation found, returned value in new data type
     * If value is not provided, then default value will be returned
     * @param entry Configuration key value entry
     * @param valueFormat Expected value format
     * @return Transformed and formatted data
     */
    private static String transformValue(Entry<String, String> entry, String valueFormat) {
    	if(valueFormat != null && !valueFormat.isEmpty()) {
    		if(entry.getValue() != null && entry.getValue() != "") {
    			return String.format(valueFormat, VALUE_TRANSFORMATIONS.get(entry.getKey()) == null 
    													? entry.getValue() 
    													: VALUE_TRANSFORMATIONS.get(entry.getKey()).apply(entry.getValue()));
    		} else {
    			return VALUE_TRANSFORMATIONS.get(entry.getKey()) == null ? null : VALUE_TRANSFORMATIONS.get(entry.getKey()).apply(entry.getValue());
    		}
    	} else {
    		return VALUE_TRANSFORMATIONS.get(entry.getKey()) == null 
					? entry.getValue() 
					: VALUE_TRANSFORMATIONS.get(entry.getKey()).apply(entry.getValue());
    	}
    }
    
    private static Map<String, String> getConfigsFromPropertiesFile(String application, String fileName) throws IOException {
        Path propertyFilePath = Paths.get(configDir, fileName);
        Map<String, String> configurations = new HashMap<>();
        File propertyFile = propertyFilePath.toFile();
        if (propertyFile.exists()) {
            Properties properties = new Properties();
            try (FileInputStream fileInputStream = new FileInputStream(propertyFilePath.toFile())) {
                properties.load(fileInputStream);
            }
            
            Set<String> excludeKeys = EXCLUDE_KEYS.get(application);
            
            for (String key : properties.stringPropertyNames()) {
            	if(excludeKeys != null 
            			&& excludeKeys.contains(key)) {
            		continue;
            	}
            	
                String value = properties.getProperty(key);
                if (value != null) {
                    value = value.trim();
                }
                configurations.put(key, value);
            }
            System.out.println(String.format("Found %d configurations in %s", configurations.size(), fileName));
        }
        return configurations;
    }

    private static Map<String, String> getConfigsFromXmlFile(String fileName, Map<String, String> mappings)
            throws IOException, ParserConfigurationException, SAXException {
        Path xmlFilePath = Paths.get(configDir, fileName);
        Map<String, String> configurations = new HashMap<>();
        File xmlFile = xmlFilePath.toFile();
        if (xmlFile.exists()) {
            Document document = DocumentBuilderFactory.newInstance()
                    .newDocumentBuilder()
                    .parse(new InputSource(new FileInputStream(xmlFile)));
            XPath xPath = XPathFactory.newInstance().newXPath();
            for (Map.Entry<String, String> entry : mappings.entrySet()) {
                String expression = entry.getValue();
                try {
                    String value = xPath.evaluate(expression, document);
                    configurations.put(entry.getKey(), value);
                } catch (XPathExpressionException e) {
                    System.out.println(String.format("Error in XPath expression %s", expression));
                    e.printStackTrace();
                }
            }
        }
        return configurations;
    }

    /*
     * This is for values in the configuration file that exist as
     * multiple elements, but have to be combined into a single
     * element for the new configuration.
     */
    private static Map<String, String> getCombiningConfigsFromXmlFile(String fileName, Map<String, CombiningMapping> mappings) throws IOException, ParserConfigurationException, SAXException {
        Path xmlFilePath = Paths.get(configDir, fileName);

        Map<String, String> configurations = new HashMap<>();
        File xmlFile = xmlFilePath.toFile();
        if (xmlFile.exists()) {
            Document document = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(new InputSource(new FileInputStream(xmlFile)));
            XPath xPath = XPathFactory.newInstance().newXPath();

            for (Map.Entry<String, CombiningMapping> entry : mappings.entrySet()) {
                ArrayList<String> values = new ArrayList<>();
                
                String expression = entry.getValue().getPath();

                try {
                    String value = xPath.evaluate("count(" + expression + ")", document);

                    int count = Integer.parseInt(value);

                    if (count > 0) {
                        for (int i = 1; i <= count; i++) {
                            values.add(xPath.evaluate(expression + "[" + i + "]/text()", document).trim());
                        }
                        
                        configurations.put(entry.getKey(), StringUtils.join(values, entry.getValue().getSeparator()));
                    }
                } catch (XPathExpressionException e) {
                    System.out.println("Error in XPath expression");
                    e.printStackTrace();
                }
            }
            
        }

        return configurations;
    }
    
    private static void moveFileToBackup(String fileName) throws IOException {
        Path backupDir = Paths.get(configDir, "backup");
        boolean backupDirectoryCreated = backupDir.toFile().mkdirs();
        if (backupDirectoryCreated) {
            System.out.println("Created the backup directory at " + backupDir);
        }
        Path source = Paths.get(configDir, fileName);
        Path target = Paths.get(configDir, "backup", fileName);
        Files.move(source, target);
        System.out.println(String.format("Moved the configuration file from %s to %s", source, target));
    }

    private static boolean verifySavedConfigurations(Connection connection, String application,
                                                     Map<String, String> configurations) throws SQLException {
        List<String> unsavedConfigurations = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(VERIFY_QUERY)) {
            for (Map.Entry<String, String> entry : configurations.entrySet()) {
                String key = getMappedKey(application, entry.getKey());
                if (key != null) {
                    boolean verified = false;
                    statement.setString(1, application);
                    statement.setString(2, key);
                    try (ResultSet rs = statement.executeQuery()) {
                        if (rs.next()) {
                            String value = rs.getString("VALUE");
                            String valueFormat = rs.getString("VALUE_FORMAT");
                            if (value == null) {
                                value = "";
                            }
                            String expectedValue = transformValue(entry, valueFormat);
                            if (expectedValue == null) {
                                expectedValue = "";
                            }
                            if (value.equals(expectedValue)) {
                                verified = true;
                            }
                        }
                    }
                    if (!verified) {
                        unsavedConfigurations.add(entry.getKey());
                        System.out.println(String.format("Configuration %s/%s=%s is not found in database table",
                                application, entry.getKey(),
                                entry.getValue()));
                    }
                }
            }
        }
        return unsavedConfigurations.isEmpty();
    }

    /**
     * This method is used to handle keys name differences between the file and the database table.
     *
     * @param application the application name
     * @param key         the value of the key as appear in the configuration file
     * @return the mapped key in the database table
     */
    private static String getMappedKey(String application, String key) {
        switch (application) {
            case APPLICATION_CONFIG_SERVICE: {
                if (KEY_MAPPINGS_BOOTSTRAP.containsKey(key)) {
                    return KEY_MAPPINGS_BOOTSTRAP.get(key);
                }
                break;
            }
            case APPLICATION_CONSOLE: {
                if (KEY_MAPPINGS_CONSOLE.containsKey(key)) {
                    return KEY_MAPPINGS_CONSOLE.get(key);
                }
                break;
            }
            case APPLICATION_ADMINISTRATOR: {
                if (KEY_MAPPINGS_ADMINISTRATOR.containsKey(key)) {
                    return KEY_MAPPINGS_CONSOLE.get(key);
                }
                break;
            }
            case APPLICATION_REPORTER: {
                if (KEY_MAPPINGS_REPORTER.containsKey(key)) {
                    return KEY_MAPPINGS_REPORTER.get(key);
                }
                break;
            }
            case APPLICATION_CAS: {
                if (KEY_MAPPINGS_CAS.containsKey(key)) {
                    return KEY_MAPPINGS_CAS.get(key);
                }
                break;
            }
        }
        return key;
    }

    private static String generateRandomPassword() {
        String randomText = new BigInteger(150, new SecureRandom()).toString(32);
        return reversibleEncryptor.encrypt(randomText);
    }

}
