#!/usr/bin/python

# Return 32-bit asm code to push obfuscated NULL byte free string to stack
# use XOR with random 32 bit key for 

# format info:
# bin: '{:0>32b}'.format(int(a[0],16),'b')
# hex: '{:0>8x}'.format(random.getrandbits(32))

import binascii
import random
from termcolor import colored

def header():
	print("|-"+70*"-"+"-|")
	print("| "+70*" "+" |")
	print("| "+"{: <70}".format("Obfuscate custom string for simple av evasion ")+" |");
	print("| "+"{: <70}".format("i.e.: WinAPI function name or commands to execute")+" |");
	print("| "+"{: <70}".format(" ")+" |");
	print("| "+"{: <70}".format("1. convert string to little endian 32 bit format")+" |");
	print("| "+"{: <70}".format("2. xor obfuscation")+" |");
	print("| "+"{: <70}".format(" ")+" |");
	print("| "+"{: <70}".format("   a ^ b = c")+" |");
	print("| "+"{: <70}".format(" ")+" |");
	print("| "+"{: <70}".format("   a = little endian dword")+" |");
	print("| "+"{: <70}".format("   b = random 32 bit key (one key per dword")+" |");
	print("| "+"{: <70}".format("   c = obfuscated dword")+" |");
	print("| "+70*" "+" |")
	print("|-"+70*"-"+"-|")

def littleEndianDwordArray(shex):
	dwordArray=[]
	for i in range(0,len(shex),8):
		for j in [shex[i:i+8]]:
			dwordArray.append(j[6:8]+j[4:6]+j[2:4]+j[0:2])
	return dwordArray

def stringToDword(shex):
	dwordArray=[]
	for i in range(0,len(shex),8):
		for j in [shex[i:i+8]]:
			dwordArray.append(j)
	return dwordArray

def padding(s,shex):
	if len(s) % 4 != 0:
		padding=4-len(s) %  4
		shex+=padding*"00"
	return shex

def obfuscate(dwords):
	print("|-"+70*"-"+"-|")
	dwordsobfuscated={"key":[],"obfuscation":[]}
	print("Given dword array: ",end='')
	print(dwords)
	for index,value in enumerate(dwords):
		key='{:0>8x}'.format(0)  	# initialize xor operand b="00000000"
		obfuscated='{:0>8x}'.format(0) 	# initialize xor operand c="00000000"
		while (obfuscated.find("00") >= 0 ) or (key.find("00") >= 0):	# avoid NULL bytes in both xor operands (or other bad chards)
			key='{:0>8x}'.format(random.getrandbits(32))
			obfuscated='{:0>8x}'.format(int(value,16) ^ int(key,16))
		print("Operator A: hex | 0x"+value + "  bin | 0b"+'{:0>32b}'.format(int(value,16),'b'))
		print("Operator B: hex | 0x"+key + "  bin | 0b"+'{:0>32b}'.format(int(key,16),'b'))
		print(" A ^ B = C: hex | 0x"+obfuscated + "  bin | 0b"+'{:0>32b}'.format(int(obfuscated,16),'b')+"\n")
		dwordsobfuscated["obfuscation"].append(obfuscated)
		dwordsobfuscated["key"].append(key)
	return dwordsobfuscated

def pushToStack(dwordsobfuscated):
	print("|-"+70*"-"+"-|")
	print("[+] Push obfuscated null terminated string to stack:")
	reg=input("[?] XOR-Register (i.e. edx): ")
	print("\nxor "+reg+","+reg)
	print("push "+reg+"\n")
	for index,key in enumerate(dwordsobfuscated["key"]):
		print("mov "+reg+",0x"+key)
		print("xor "+reg+",0x"+dwordsobfuscated["obfuscation"][index])
		print("push "+reg+"\n")

		

header()
s=input("[?] String to obfuscate: ")
shex=str(binascii.hexlify(s.encode()))[2:-1]
shex=padding(s,shex)

print("[+] String: "+s+" | Hex: "+shex+" | Size: "+str(len(s))+" byte | Padding: "+str(4-len(s) % 4)+" byte")
dwords=littleEndianDwordArray(shex)
print("|-"+70*"-"+"-|")
print("[+] Split string in dwords and convert these to little endian 32 bit:")
for dword in dwords:
	print("0x"+dword)

print("[+] Stack friendly reversed order:")
dwords.reverse()
for dword in dwords:
	print("0x"+dword)

dwordsobfuscated=obfuscate(dwords)
pushToStack(dwordsobfuscated)
