# -*- coding: utf-8 -*-

"""
  my_resume application
    
  Test like so: python3 -m pytest tests/
  :copyright: (c) by Franklin Diaz
  :license: MIT
"""

import pytest
from werkzeug.datastructures import ImmutableMultiDict
from flask import request

def test_404(client):
  request.form = ImmutableMultiDict([('submit_button', 'Go Back to Resume')])
  response = client.get('/garbage')
  assert client.get('/garbage').status_code == 404