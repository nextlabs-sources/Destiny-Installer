package com.nextlabs.installer.controlcenter.validatelicense;

import static java.lang.System.currentTimeMillis;

import java.io.File;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLClassLoader;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map.Entry;
import java.util.Properties;
import java.util.Set;

public class LicenseChecker {

	private static final String LICENSE_JARCHECKER_CLASS_NAME = "com.wald.license.checker.JarChecker";
	private static final String LICENSE_CLASSLOADER_CLASS_NAME = "com.wald.license.checker.LicenseClassLoader";
	private static final String LICENSE_JARCHECKER_GETPROPERTIES_METHOD_NAME = "getProperties";
	private static final String LICENSE_JARCHECKER_CHECK_METHOD_NAME = "check";
	private static final String LICENSE_JARCHECKER_SETCLASSLOADER_METHOD_NAME = "setClassLoader";
	private static final String LICENSE_JARCHECKER_SETJARFILENAME_METHOD_NAME = "setJarFileName";
	private static final String FILE_PROTOCOL = "file:///";
	private static final long LICENSE_NEVER_EXPIRE = Long.MAX_VALUE;
	private static long licenseExpireTime = 0;
	private static Properties licenseProperties = null;
	private static Object LOAD_LICENSE_LOCK = new Object();

	private String licenseJarFileLocation;
	private String licenseDataFileLocation;

	public LicenseChecker(String licenseJarFileLocation, String licenseDataFileLocation) {
		this.licenseDataFileLocation = licenseDataFileLocation;
		this.licenseJarFileLocation = licenseJarFileLocation;
	}

	private boolean isValidLicense() throws Exception {
		try {
			if (licenseProperties == null) {
				synchronized (LOAD_LICENSE_LOCK) {
					if (licenseProperties == null) {
						licenseProperties = loadedLicense(this.licenseJarFileLocation);
						if (null != licenseProperties) {
							Set<Entry<Object, Object>> entrySet = licenseProperties.entrySet();
							for (Entry<Object, Object> entry : entrySet) {
								licenseProperties.setProperty(((String) entry.getKey()).toLowerCase(),
										(String) entry.getValue());
							}
							String expirationDate = licenseProperties.getProperty("expiration");

							if (expirationDate.equals("-1")) {
								licenseExpireTime = LICENSE_NEVER_EXPIRE;
							} else {
								DateFormat dateFormter = new SimpleDateFormat("MM/dd/yyyy");
								Date expiryDate = dateFormter.parse(expirationDate);
								licenseExpireTime = expiryDate.getTime();
							}
						}
					}
				}
			}

			if (licenseProperties != null) {
				return licenseExpireTime >= currentTimeMillis();
			}
		} catch (Exception e) {
			throw e;
		}
		return false;
	}

	private Properties loadedLicense(String licenseFolderLocation) throws MalformedURLException, ClassNotFoundException,
			NoSuchMethodException, InstantiationException, IllegalAccessException, InvocationTargetException {

		URL jarLocation = new URL(FILE_PROTOCOL + this.licenseJarFileLocation);
		String licenseDataFileDirectory = new File(this.licenseDataFileLocation).getParent();
		URL dataFileParentFolderLocation = new URL(FILE_PROTOCOL + licenseDataFileDirectory);
		URL[] classLoaderURLs = { jarLocation, dataFileParentFolderLocation };
		ClassLoader licenseLocationClassLoader = new URLClassLoader(classLoaderURLs, this.getClass().getClassLoader());

		Class<?> licenseClassLoaderClass = licenseLocationClassLoader.loadClass(LICENSE_CLASSLOADER_CLASS_NAME);
		Constructor<?> parentClassLoaderConstructor = licenseClassLoaderClass.getConstructor(ClassLoader.class);
		Object licenseClassLoader = parentClassLoaderConstructor.newInstance(licenseLocationClassLoader);

		Class<?> jarCheckerClass = licenseLocationClassLoader.loadClass(LICENSE_JARCHECKER_CLASS_NAME);
		Object jarCheckerInstance = jarCheckerClass.newInstance();
		Method setJarFileMethod = jarCheckerClass.getMethod(LICENSE_JARCHECKER_SETJARFILENAME_METHOD_NAME,
				java.lang.String.class);
		setJarFileMethod.invoke(jarCheckerInstance, licenseJarFileLocation);

		Class<?> setClassLoaderMethodParams = licenseClassLoader.getClass();
		Method setClassLoaderMethod = jarCheckerClass.getMethod(LICENSE_JARCHECKER_SETCLASSLOADER_METHOD_NAME,
				setClassLoaderMethodParams);
		setClassLoaderMethod.invoke(jarCheckerInstance, licenseClassLoader);

		Method checkMethod = jarCheckerClass.getMethod(LICENSE_JARCHECKER_CHECK_METHOD_NAME);
		checkMethod.invoke(jarCheckerInstance);

		Method getPropertiesMethod = jarCheckerClass.getMethod(LICENSE_JARCHECKER_GETPROPERTIES_METHOD_NAME);
		return (Properties) getPropertiesMethod.invoke(jarCheckerInstance);
	}

	public static void main(String args[]) {
		String licenseJarFileLocation = System.getProperty("license.jar.file.loc");
		String licenseDataFileLocation = System.getProperty("license.data.file.loc");
		LicenseChecker licenseChecker = new LicenseChecker(licenseJarFileLocation, licenseDataFileLocation);
		try {
			System.out.println(licenseChecker.isValidLicense());
		} catch (Exception e) {
			System.out.println("Error in validating license file : " + e.getMessage());
		}
	}
}
