#!/bin/bash

cp -rv /home/inb/lconcha/FEI ~/.config/
echo "MCSLMD_LICENSE_FILE=/home/inb/`whoami`/.config/FEI/serverFile.dat"  > ${HOME}/.flexlmrc

echo "Try to open amira, simply use the command zib"
