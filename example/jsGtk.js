gtkInit(1,['jsGtk']);

w = gtk.const_get('Window').new(0);

b=gtk.const_get('Button').new_with_label('quit');
connect(b,'clicked',gtkMainQuit);

w.add(b);
w.show_all();

gtkMain();
