package com.nextlabs.installer.controlcenter.generator;

import java.util.Base64;

import javax.crypto.SecretKey;

public class KeyGenerator {
	
	public static void main(String[] args) {
		try {
			if(args == null || args.length < 2) {
				System.out.println("java [-options] class KeyGenerator <algorithm> <key size>");
			} else {
				javax.crypto.KeyGenerator keyGen = javax.crypto.KeyGenerator.getInstance(args[0]);
				keyGen.init(Integer.parseInt(args[1]));
				SecretKey secretKey = keyGen.generateKey();
				
				System.out.println(Base64.getEncoder().encodeToString(secretKey.getEncoded())); 
			}
		} catch(Throwable throwable) {
			System.out.println(throwable.getMessage());
		}
	}
}
