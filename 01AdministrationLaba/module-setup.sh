#!/bin/bash

check(){
        return 0
}       

depends(){
        return 0
}       

install(){
        inst_hook cleanup 00 "${moddir}/1laba_dracut.sh"
} 
