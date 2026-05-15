#!/bin/bash
export QT_SELECT=5
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
exec qmlscene "$SCRIPT_DIR/main.qml"
