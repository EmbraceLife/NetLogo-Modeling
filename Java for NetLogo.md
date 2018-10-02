# Java with BlueJ 
## Objectives

> to read and understand [this repo](https://github.com/EconomicSL/housing-model) 
>
> to read and understand NetLogo source code (not necessary now)
>
> - make small adjustment to source code to [suit personal preference](https://stackoverflow.com/questions/52586224/how-to-adjust-netlogo-source-code-to-fold-view-window-of-monitor-window-when-run)  

[BlueJ with git](https://www.bluej.org/tutorial/git/)

## Introduction to Class 

> [What is class](https://youtu.be/CPUaTT0Xoo4?list=PLYPWr4ErjcnzWB95MVvlKArO6PIfv1fHd)

## Creating and Inspecting Ojbects

> [Creating and Using objects within BlueJ](https://youtu.be/jIm-squNyAs?list=PLYPWr4ErjcnzWB95MVvlKArO6PIfv1fHd)  Video 
>
> [Project 1](../../../BlueJ 4.1.3/BlueJ projects/chapter01/figures/package.bluej) .bluej
>
> Exactly like how we create, manipulate and inspect agents in NetLogo

## Methods and Parameters 

> [Inspect object and experiment methods and parameters](https://youtu.be/hjaFFdpbGoQ?list=PLYPWr4ErjcnzWB95MVvlKArO6PIfv1fHd) Video
>
> [Project 1](../../../BlueJ 4.1.3/BlueJ projects/chapter01/figures/package.bluej) .bluej
>
> - inspect two objects to compare them side by side, exactly like what we did in NetLogo debug
>
> **Great feature of BlueJ** 
>
> - right click object in red (not Class in diagram) to check and run all their methods at your will
> - through dialogue window to offer inputs (for parameters, can be more than 1) to the methods

## Add a function into source code 

> [solving a challenge exercise](https://youtu.be/inZ1pamustg?list=PLYPWr4ErjcnzWB95MVvlKArO6PIfv1fHd)  video 
>
> [house project](../../../BlueJ 4.1.3/BlueJ projects/chapter01/house/package.bluej) .bluej
>
> **Project Features** 
>
> - bring a number of different classes together to create a new class, Picture
> - add a function or action to  `draw` function of Picture class
> - from inspect Picture (combined) object and further inspect its component objects 
> - take the first glance at the source code, see the structure of a class
> - learn to modify functions

## Try out class, object, methods before reading source code 

> [video](https://youtu.be/LIbL64bBO9s?list=PLYPWr4ErjcnzWB95MVvlKArO6PIfv1fHd)
>
> [ticket machine project](../../../BlueJ 4.1.3/BlueJ projects/chapter02/naive-ticket-machine/package.bluej)
>
> Features 
>
> - to examine the use of class, object and methods before reading source code 
> - each method is executed through a dialogue with instruction, input, or return values 
> - through inspect we check the states or fields of the object

## How to read source code 

> [video](https://youtu.be/9goaOqbkC24?list=PLYPWr4ErjcnzWB95MVvlKArO6PIfv1fHd)
>
> [ticket machine project](../../../BlueJ 4.1.3/BlueJ projects/chapter02/naive-ticket-machine/package.bluej)
>
> Features 
>
> - how to use BlueJ editor 
> - how to write Class, constructor

## How to write a class from scratch 

> [video](https://youtu.be/Y9gOv-swR9M?list=PLYPWr4ErjcnzWB95MVvlKArO6PIfv1fHd)
>
> [Heater Exercise](../../../BlueJ 4.1.3/BlueJ projects/chapter02/Heater Exercise)
>
> Features
>
> - start a new project, write README 
> - write comments 
>   - single comment with `//` with `cmd + option + c` 
>   - block of documents with `/** + enter`   
> - write Class, constructor and methods 
>   - `()` and `{}`  and `;` 
> - compile shorcut : `cmd + k` 
> - compile and test the function or class at every small step 
>   - crucial to avoid hidden errors 
> - use of `this` : `this.temperature = temperature; `  

## How One class uses other classes

> [Fields of class types video](https://youtu.be/72DsdvA80yo?list=PLYPWr4ErjcnzWB95MVvlKArO6PIfv1fHd) 
>
> [clock-display](../../../BlueJ 4.1.3/BlueJ projects/chapter03/clock-display)
>
> Features 
>
> - understand meaning of `public`, `private` 
> - `private int limit;`
> - `public NumberDisplay(int rollOverLimit){}` 
> - `public int getValue(){}`
> - `public String getDisplayValue(){}`
> - `if(value < 10) {return "0" + value;} else {return "" + value;}`
> - `public void setValue(int replacementValue){}`
> - `if((replacementValue >= 0) && (replacementValue < limit)) {}`
> - `public void increment(){}`
> - `private NumberDisplay hours;` 
> - `private String displayString; `
> - `hours = new NumberDisplay(24);`
> - `private void updateDisplay(){}` 
> - `hours.setValue(hour);`
> - `displayString = hours.getDisplayValue() + ":" + minutes.getDisplayValue();`

## How to use Debugger

> [video](https://youtu.be/AbEVfqG-sZc?list=PLYPWr4ErjcnzWB95MVvlKArO6PIfv1fHd)
>
> [clock-display](../../../BlueJ 4.1.3/BlueJ projects/chapter03/clock-display)
>
> Features
>
> - break
> - step, step-into, continue

## How to build and use Test class

> [video](https://youtu.be/1p5Uf7LDoO0?list=PLYPWr4ErjcnzWB95MVvlKArO6PIfv1fHd)
>
> [clock-display](../../../BlueJ 4.1.3/BlueJ projects/chapter03/clock-display)
>
> Features
>
> - build a class
> - build a test method and gradually add more test cases into it

## How to import other class library

> [video](https://youtu.be/_75i6SCwVPM?list=PLYPWr4ErjcnzWB95MVvlKArO6PIfv1fHd)
>
> [music-organizer-v1](../../../BlueJ 4.1.3/BlueJ projects/chapter04/music-organizer-v1)
>
> Features 
>
> - how to import ArrayList class
> - how to create ArrayList object 
> - use its methods ArrayList.get , add, remove

## 4 classes work together 

> [video](https://youtu.be/6-A1g2liBh4?list=PLYPWr4ErjcnzWB95MVvlKArO6PIfv1fHd)
>
> [auction](../../../BlueJ 4.1.3/BlueJ projects/chapter04/auction)  
>
> Features
>
> - how to do for loop
> - how to use multiple classes in a new class