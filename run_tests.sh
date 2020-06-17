#!/bin/bash

export UUID=$(uuidgen)
export PLATFORM=$1
export RESULT_FOLDER=./${PLATFORM}_results

SECONDS=0

# run test on firebase
echo -e "\n * * * * * *  RUN $PLATFORM TESTS  * * * * * * \n"

if [[ $PLATFORM == 'ios' ]]; then
	gcloud firebase test ios run \
		--test /Users/mesut/Desktop/vngrs-toolset-ios/Build/Products/Movies.zip \
		--device model=iphone11,version=13.3,locale=tr_TR,orientation=portrait \
		--xcode-version=11.3.1 \
		--results-dir=$UUID
else
	gcloud firebase test android run \
     --type instrumentation \
     --app /Users/mesut/Projects/vngrs-toolkits/android-mvvm-coroutines/app/build/outputs/apk/debug/app-debug.apk \
     --test /Users/mesut/Projects/vngrs-toolkits/android-mvvm-coroutines/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
     --device model=Nexus5,version=23 \
     --environment-variables coverage=true,coverageFile="/sdcard/coverage.ec" \
     --directories-to-pull /sdcard \
     --timeout 100 \
     --test-targets "package app.vngrs.githubchallenge" \
     --results-dir=$UUID
fi

# remove files
echo -e "\n * * * * * *  REMEVE OLD RESULT FILES  * * * * * *\n"
rm -rf ${RESULT_FOLDER}/*

# copy test results to result folder
echo -e " * * * * * *  COPY NEW RESULTS FROM GOOGLE STORAGE  * * * * * *\n"
gsutil -m cp $(gsutil -m ls -r gs://test-lab-bf1n357ywd082-jay5aybvyr3j0/$UUID | egrep "(.*)/test_result_(.*).xml") $RESULT_FOLDER

# export data to elasticsearch
echo -e "\n * * * * * *  EXPORT DATA TO ELASTICSEARCH  * * * * * *\n"
python3.6 export_xml_data_elastic.py $PLATFORM


duration_total=$SECONDS
echo -e "\n\n - $(($duration_total / 60)) minutes and $(($duration_total % 60)) seconds elapsed.\n"
echo -e "\n * * * * * * *  RESTORE FINISHED  * * * * * * *\n"
