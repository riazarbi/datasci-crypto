FROM riazarbi/datasci-gui-minimal:20211230082307

LABEL authors="Riaz Arbi"

# Be explicit about user
# This is because we switch users during this build and it can get confusing
USER root

RUN pip3 install luno-python
    
# Run as NB_USER ============================================================

USER $NB_USER
