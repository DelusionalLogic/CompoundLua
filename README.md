CompundLua
==========

Simple compound statement solver in lua

Usage
==========

To run the program simply execute discrete.lua, the only parameter needed is the statement you would like to evalualte. If this is not provided a default statement of `If p then q`

The statements are slightly different from the normal logical operators.
 
not p is written `-p`
p and q is written `p^q`
p or q is written `pvq` (Making v not a valid variable)
p exclusive or is written `p*q`
if p then q is written `p>q`
p if and only if q is written `p<q`

If two statements are provided as parameters then they will be compared the program will write true if they are equivalent
