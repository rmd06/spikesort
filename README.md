# spikesort

Spike sorting for Kontroller

![image](images/hero.png)

`spikesort` can read data generated by [Kontroller](https://github.com/sg-s/kontroller) and help you sort spikes from multiple neurons in a single extracellular voltage recording. This was developed for sorting the action potentials of Drosophila Olfactory Receptor Neurons, but would probably work in other contexts. 

## Features

### Fast Filter and Find Spikes in trace

![](images/spikes.gif)

### Several algorithms for dimensional reduction

Every problem is different. To deal with unknown unknowns, `spikesort` ships with a number of methods for dimensionality reduction. All these methods are built around an awesome [plugin](#plugin-architecture) architecture, making inclusion of new methods a breeze.  

### Several algorithms for data clustering

Likewise, data clustering is achieved through plugins, allowing you to customise `spikesort` for any task. 

### Native support for [Kontroller](https://github.com/sg-s/kontroller)-generated data

![](images/kontroller.png)

### export all traces to EPS figures.

### BSD xattr-based file tagging. 

Limited support for the [extended file attribute](http://en.wikipedia.org/wiki/Extended_file_attributes) system on *nix-like systems. `spikesort` automatically tags files it touches so it makes working with lots of files easier. 

## Limitations 

* for various reasons, sorting into only two groups (A and B) is supported. spikesort will not support more than 2 groups

## Installation

spikesort is written in MATLAB.

The best way to install spikesort is through my package manager: 

```
>> urlwrite('http://srinivas.gs/install.m','install.m'); 
>> install spikesort
>> install srinivas.gs_mtools # spikesort needs this package to run
```

This script grabs the code and fixes your path. 

Or, if you have `git` installed:

````
git clone git@github.com:sg-s/spikesort.git
````

or use [this link](https://github.com/sg-s/spikesort/archive/master.zip).

# Hacking

## Plugin architecture

`spikesort` is built around a plugin architectue for the two most important things it does: 

* dimensionality reduction of spike shapes
* clustering 

### Default plugins

`spikesort` ships with the following default plugins for dimensionality reduction:

1. (1D) spike amplitudes
2. (1D) fractional spike amplitudes
3. (1D) relative spike amplitudes
3. (2D) Principal Components 

and the following default plugins for clustering:

1. (1D) Gaussian Mixture Models
2. (2D) Manual Clustering 
3. (ND) Density-Peaks clustering 

### Writing your own plugins

Writing your own plugins is really easy: `spikesort` does the heavy lifting in figuring out how to talk to it, and all you have to is write a function that conforms to a few standards:

#### Naming.
Dimensionality reduction plugins have to be called `ssdm_foo.m` and clustering method plugins have to be called `sscm_bar.m`. Put them in the same folder as 	`spikesort` and it will automatically include them. 

#### Outputs
A dimensionality reduction plugin is a function must return a variable called `R`, that is usually a vector or a matrix (but can be whatever you want)

A clustering plugin is a function that must return two variables `A` and `B` that indicate vector indices of spikes of neuron 1 and neuron 2 in the current voltage trace. 

#### Inputs
Both types of plugins are functions that can have any inputs whatsoever -- provided you reference the correct variable names in spikesort. Since `V` is a variable used to denote the filtered voltage in `spikesort`, you can ask for `V` in your function definition as follows:

```
function R = ssdm_my_awesome_plugin(V,foo,bar)
```

and `spikesort` will intelligently give your function the correct variables in the correct order (spikesort reads your function and figures this out). So you can write plugins that work with any variable in the main `spikesort` codebase without altering it in any way.

#### Variable Names

Here is a non-exhaustive list of some useful internal variables that `spikesort` uses that you might want to use in your plugin:

* `V` a vector, contains the raw voltage trace
* `Vf` a vector, contains the filtered voltage trace
* `loc` a vector, contains the vector indices of putative spikes
* `ax`, `ax2` handles to the two main axes. Useful if your plugin does some fancy plotting.  
* `V_snippets` a matrix containing snippets around `loc` from `Vf`. Useful if you just want to work with the spike shapes, and don't really care where they are. 

# License 

[GPL v2](http://choosealicense.com/licenses/gpl-2.0/#)

