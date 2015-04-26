#!/bin/sh
#BSUB -J convnet-make-data 
#BSUB -o output_file
#BSUB -e error_file
#BSUB -n 16
#BSUB -q ht-10g
#BSUB -R "span[ptile=8]"
#BSUB -cwd /home/vaskevich.o/eece5640/_project/convnet-nu-discovery/make-data
######## THIS IS A TEMPLATE FILE FOR TCP ENABLED MPI RUNS ON THE DISCOVERY CLUSTER ########
#### #BSUB -n has a value equal to the given value for the -np option ####
# prefix for next run is entered below
# file staging code is entered below

#### Enter your working directory below - this is the string returned from issuing the command 
#### "pwd"
#### IF you stage your files this is your run directory in the high speed scratch space mounted 
#### across all compute nodes
work="/home/vaskevich.o/eece5640/_project/convnet-nu-discovery/make-data"
scratch_username="vaskevich.o"
#####################################################
########DO NOT EDIT ANYTHING BELOW THIS LINE#########
#####################################################
cd "$work"
tempfile1=hostlistrun
tempfile2=hostlist-tcp
echo $LSB_MCPU_HOSTS > $tempfile1
declare -a hosts
read -a hosts < ${tempfile1}
for ((i=0; i<${#hosts[@]}; i += 2)) ; 
do 
   HOST=${hosts[$i]}
   CORE=${hosts[(($i+1))]} 
   echo $HOST:$CORE >> $tempfile2
done
#####################################################
########DO NOT EDIT ANYTHING ABOVE THIS LINE#########
#####################################################
###### Change only the -np option giving the number of MPI processes and the executable to use 
###### with options to it
###### IN the example below this would be "8", "helloworld.py" and the options for the executable 
###### DO NOT CHANGE ANYTHING ELSE BELOW FOR mpirun OPTIONS
###### MAKE SURE THAT THE "#BSUB -n" is equal to the "-np" number below. IN this example it is 8.

mpirun -np 16 -prot -TCP -lsf make-data.py --src-dir "/scratch/$scratch_username/data" --tgt-dir "/scratch/$scratch_username/batch"

#/home/nroy/mpi4py-test/helloworld.py
# any clean up tasks and file migration code is entered below
#####################################################
########DO NOT EDIT ANYTHING BELOW THIS LINE#########
#####################################################
rm "$work/$tempfile1"
rm "$work/$tempfile2"
#####################################################
########DO NOT EDIT ANYTHING ABOVE THIS LINE#########
#####################################################

