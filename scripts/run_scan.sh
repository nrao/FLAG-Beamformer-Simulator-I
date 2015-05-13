# Copyright (C) 2015 Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning GBT software should be addressed as follows:
# GBT Operations
# National Radio Astronomy Observatory
# P. O. Box 2
# Green Bank, WV 24944-0002 USA

wait()
{
    echo "> Waiting to continue"
    read
}

# echo "> Cleaning up..."
# /home/sandboxes/tchamber/paper/simulator_1/scripts/cleanup.sh


# Run the fake_gpu
echo "> Starting the fake_gpu hashpipe plugin"
taskset 0x0606 hashpipe -p fake_gpu -I 0 -o BINDHOST=px1-2.gb.nrao.edu -o GPUDEV=0 -o XID=0 -c 3 fake_gpu_thread &
hash_pid=$!
echo "The PID of the hashpipe instance running fake_gpu is: ${hash_pid}"

# wait

# Set status memory keys
echo "> Setting status keys required for vegasFitsWriter"
./set_status.sh

# Runs dmjd script to set up start times; passes all our arguments to it
echo "> Setting start time related status keys"
python ./dmjd.py "$@"

# wait

#Run the fits writer
echo "> Running fits writer"
/home/sandboxes/tchamber/vegas_devel3/vegas_devel/src/dibas_fits_writer/vegasFitsWriter &
vegas_pid=$!
echo "The PID of the vegasFitsWriter is: ${vegas_pid}"

# wait

# Start
echo "> Starting fake_gpu"
echo "START" > /tmp/fake_gpu_control

# wait

echo "> Starting vegas fits io"
echo "START" > /tmp/vegas_fits_control

echo "> ---------------PRESS ANY KEY TO QUIT---------------"
wait

echo "> Killing PID ${hash_pid}"
kill ${hash_pid}


if [ ${hash_pid} ]
then
  echo "> fake_gpu has exited cleanly"
else
    echo "> fake_gpu has failed to exit cleanly. SIGKILL? \"y\" for yes"
    read res
    if [ ${res} = "y" ]; then
        kill -9 $(hash_pid)
    fi
fi

echo "QUIT" > /tmp/vegas_fits_control
echo "> vegasFitsWriter should have exited cleanly"

if [ ${vegas_pid} ]
then
  echo "> vegasFitsWriter has exited cleanly"
else
    echo "> vegasFitsWriter has failed to exit cleanly. SIGKILL? \"y\" for yes"
    read res
    if [ ${res} = "y" ]; then
        kill -9 ${vegas_pid}
    fi
fi

