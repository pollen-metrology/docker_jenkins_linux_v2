#!/bin/bash
counter=0
isPassing=0
globalLines=57.0
globalFunctions=55.3
pluginsLines=29.0
pluginsFunctions=37.6
modulesLines=70.9
modulesFunctions=62.2
while read value
do
   if [ "$counter" -eq 0  ];then
      if [ $(echo "$value >= $globalLines"|bc) -eq 1 ];then
         printf -- "Global coverage for lines: $value%% \n"
         let "counter++"
      else
         printf -- "Global coverage for lines: $value%% (under acceptable limit = $globalLines%%) \n"
         isPassing=1;
         let "counter++"
      fi
   elif [ "$counter" -eq 1 ];then
      if [ $(echo "$value >= $globalFunctions"|bc) -eq 1 ];then
         printf -- "Global coverage for functions: $value%% \n"
         let "counter++"
      else
         printf --  "Global coverage for functions: $value%% (under acceptable limit = $globalFunctions%%) \n"
         isPassing=1
         let "counter++"
      fi
   elif [ "$counter" -eq 2 ];then
      if [ $(echo "$value >= $pluginsLines"|bc) -eq 1 ];then
         printf --  "Plugins coverage for lines: $value%% \n"
         let "counter++"
      else
         printf --  "Plugins coverage for lines: $value%% (under accpetable limit = $pluginsLines%%) \n"
         isPassing=1
         let "counter++"
      fi
   elif [ "$counter" -eq 3 ];then
      if [ $(echo "$value >= $pluginsFunctions"|bc) -eq 1 ];then
         printf --  "Plugins coverage for functions: $value%% \n"
         let "counter++"
      else
         printf --  "Plugins coverage for functions: $value%% (under acceptable limit = $pluginsFunctions%%) \n"
         isPassing=1
         let "counter++"
      fi
   elif [ "$counter" -eq 4 ];then
      if [ $(echo "$value >= $modulesLines"|bc) -eq 1 ];then
         printf -- "Modules coverage for lines: $value%% \n"
         let "counter++"
      else
         printf --  "Modules coverage for lines: $value%% (under accceptable limit = $modulesLines%%) \n"
         isPassing=1
         let "counter++"
      fi
   else
      if [ $(echo "$value >= $modulesFunctions"|bc) -eq 1 ];then
         printf --  "Modules coverage for functions: $value%% \n"
         let "counter++"
      else 
         printf --  "Modules coverage for functions: $value%% (under acceptable limit = $modulesFunctions%%) \n"
         isPassing=1
         let "counter++"
      fi
   fi  
done < $1

exit $isPassing
