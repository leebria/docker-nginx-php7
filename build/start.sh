#!/usr/bin/env bash

systemctl enable supervisor.service

service supervisor start
