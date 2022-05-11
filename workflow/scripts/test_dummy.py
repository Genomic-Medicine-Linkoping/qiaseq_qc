# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

__author__ = "ljmesi"
__copyright__ = "Copyright 2022, ljmesi"
__email__ = "lauri.mesilaakso@regionostergotland.se"
__license__ = "GPL-3"


def test_dummy():
    from dummy import dummy
    assert dummy() == 1
