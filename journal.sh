# venv
python3 -m venv venv
source venv/bin/activate

# Install dependencies

#  ! install websocket before websocket-client !
pip install websocket
pip install websocket-client

pip install kafka-python