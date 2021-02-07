#!/bin/bash

google-authenticator --time-based --disallow-reuse --force --rate-limit=3 --rate-time=30 --emergency-codes=10 --window-size=3
