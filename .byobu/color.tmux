#!/bin/sh
# Function originally defined in /usr/lib/byobu/include/shutil

color_map() {
	case "$1" in
		k) _RET="black" ;;
		r) _RET="red" ;;
		g) _RET="green" ;;
		y) _RET="yellow" ;;
		b) _RET="blue" ;;
		m) _RET="magenta" ;;
		c) _RET="cyan" ;;
		w) _RET="white" ;;
		d) _RET="color0" ;;
		K) _RET="#555555" ;;
		R) _RET="#FF0000" ;;
		G) _RET="#00FF00" ;;
		Y) _RET="#FFFF00" ;;
		B) _RET="#0000FF" ;;
		M) _RET="#FF00FF" ;;
		C) _RET="#00FFFF" ;;
		W) _RET="#FFFFFF" ;;
		*) _RET= ;;
	esac
}
