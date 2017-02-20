http://people.csail.mit.edu/tomasz/exemplarsvm/tutorial/esvm_demo_train_synthetic.html

one can use the above tutorial to train esvms using their own data but 
with similar parameters.

Note that some hyper parameter must be modified,e.g.
(1) hog cell and grid sizes
(2) intersection threshold about the ground truth bounding box
(3) this library has different annotation scheme. Before using this lib,
one should unify the bounding box annotation.

see the evernote for details.