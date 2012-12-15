ruby-ackley-genetic-algorithm
=============================

A Genetic Algorithm for the Ackley Optimisation Problem, written in Ruby.

This is code I submitted as a student. It is not suitable for production usage.

Usage
=====

First, a warning: Genetic Algorithms written in Ruby by students are really, really slow.

    ruby multirun.rb
    ruby consolidate_data.rb
    gnuplot < data/combined.plot

This will run 288 experiments, consolidate the logged info and dump graphs of each experiment in graphs/.