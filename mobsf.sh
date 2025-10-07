#!/bin/bash

DYNAMIC=""
MODE=""
MOBSF_ANALYZER_IDENTIFIER=""
MOBSF_CORELLIUM_API_KEY=""
PERSISTENCE=""

echo -e "ENSURE YOU HAVE DOCKER AND THE MobSF IMAGE\n"
sleep 1
echo -e "You must run any of the supported Genymotion Android VM/ Android Studio Emulator before running MobSF\n"
sleep 1

while true
do
	echo -n "Continue (y) | Stop (n): "
	read
	
	if [[ "$REPLY" == "n" || "$REPLY" == "N" ]]
	then
		exit 0
	fi
	
	if [[ "$REPLY" == "Y" || "$REPLY" == "y" ]]
	then
		echo ""
		break
	fi
	echo ""
done 
	

helpFunction()
{
	echo ""
	echo -e "\tmobile-security-framework-mobsf"
	
	echo ""
	echo -e "\t-d for static and dynamic analysis support for Android"
	echo -e "\t-D for static and dynamic analysis support for IOS"
	echo -e "\t-s for static analysis support only"
	echo -e "\t-v enable persistence - ensure you pass a created local dir with chown 9901:9901 <your_local_dir>"
	echo ""
	
	echo "Examples:" 
	echo -e "\tmobsf -s  <static analysis>"
	echo -e "\tmobsf -s -v \"/home/vanblis/MOBSF\" <static analysis and persistence enabled>"
	
	echo -e "\tmobsf -d MOBSF_ANALYZER_IDENTIFIER <android dynamic analysis>"
	echo -e "\tmobsf -d MOBSF_ANALYZER_IDENTIFIER -v \"/home/vanblis/MOBSF\" <android dynamic analysis and persistence enabled>"
	
	echo -e "\tmobsf -D MOBSF_CORELLIUM_API_KEY - <ios dynamic analysis>"
	echo -e "\tmobsf -D MOBSF_CORELLIUM_API_KEY -v \"/home/vanblis/MOBSF\" <ios dynamic analysis and persistence enabled>"
	
	exit 1
}

# check that dynamic analysis is properly chosen
check_dynamic()
{
	if [[ $MOBSF_CORELLIUM_API_KEY && $MOBSF_ANALYZER_IDENTIFIER ]]
	then
		helpFunction
	fi
	
	
	if [[ $MOBSF_ANALYZER_IDENTIFIER ]]
	then
		DYNAMIC="ANDROID"
	fi
	
	if [[ $MOBSF_CORELLIUM_API_KEY ]]
	then
		DYNAMIC="IOS"
	fi
}

# check that dynamic is not chosen 
check_static()
{
	if [[ $DYNAMIC && $STATIC ]]
	then
		helpFunction
	fi
	
	if [[ $STATIC ]]
	then
		MODE="STATIC"
	fi
	
	if [[ $DYNAMIC  ]]
	then
		MODE="DYNAMIC"
	fi
	
	if [[ ! $STATIC && ! $DYNAMIC ]]
	then
		helpFunction
	fi
}


while getopts ":d:D:sv:" opt
do
	case "$opt" in
		d ) MOBSF_ANALYZER_IDENTIFIER="$OPTARG" ;;
		D ) MOBSF_CORELLIUM_API_KEY="$OPTARG" ;;
		s ) STATIC="TRUE" ;;
		v ) PERSISTENCE="$OPTARG" ;;
		? ) helpFunction ;;
		: ) helpFunction ;;
	esac
done


check_dynamic
check_static 

# check for surplus or no arguments 
if [[ "$STATIC" ]] 
then 
	if [[ $# -eq 1 ]] || [[ $# -eq 3 && "$2" == "-v"  ]]; then true ;else helpFunction; fi
elif [[ "$DYNAMIC" ]]
then
	if [[ $# -eq 2 && "$2" != "-v" ]] || [[ $# -eq 4 && "$3" == "-v"  ]]; then true ;else helpFunction; fi
else
	helpFunction
fi


# Run MobSF with Static Analysis Support
if [[ $STATIC ]]
then
	if [[ $PERSISTENCE ]]
	then
		echo -e "STARTING STATIC ANALYSIS WITH PERSISTENCE\n\n"
		docker run -it --rm -p 8000:8000 -v "$PERSISTENCE":/home/mobsf/.MobSF opensecurity/mobile-security-framework-mobsf:latest
	else
		echo -e "STARTING STATIC ANALYSIS\n\n"
		docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf:latest
	fi
fi

# Run MobSF with Static & Android Dynamic Analysis Support
if [[ "$DYNAMIC" == "ANDROID" ]]
then
	if [[ $PERSISTENCE ]]
	then
		echo -e "STARTING ANDROID DYNAMIC ANALYSIS WITH PERSISTENCE\n\n"
		docker run -it --rm -p 8000:8000 -p 1337:1337 -v "$PERSISTENCE":/home/mobsf/.MobSF -e MOBSF_ANALYZER_IDENTIFIER=$MOBSF_ANALYZER_IDENTIFIER opensecurity/mobile-security-framework-mobsf:latest
	else
		echo -e "STARTING ANDROID DYNAMIC ANALYSIS\n\n"
		docker run -it --rm -p 8000:8000 -p 1337:1337 -e MOBSF_ANALYZER_IDENTIFIER=$MOBSF_ANALYZER_IDENTIFIER opensecurity/mobile-security-framework-mobsf:latest
	fi
fi

# Run MobSF with Static & iOS Dynamic Analysis Support
if [[ "$DYNAMIC" == "IOS" ]]
then
	if [[ $PERSISTENCE ]]
	then
		echo -e "STARTING IOS DYNAMIC ANALYSIS WITH PERSISTENCE\n\n"
		docker run -it --rm -p 8000:8000 -p 1337:1337 -v "$PERSISTENCE":/home/mobsf/.MobSF -e MOBSF_CORELLIUM_API_KEY=$MOBSF_CORELLIUM_API_KEY opensecurity/mobile-security-framework-mobsf:latest
	else
		echo -e "STARTING IOS DYNAMIC ANALYSIS\n\n"
		docker run -it --rm -p 8000:8000 -p 1337:1337 -e MOBSF_CORELLIUM_API_KEY=$MOBSF_CORELLIUM_API_KEY opensecurity/mobile-security-framework-mobsf:latest
	fi
fi
