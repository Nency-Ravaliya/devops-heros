Understanding softlink and hardlink!

I created a file original.txt with the content Hello DevOps Hero (cat "Hello DevOps Hero" > original.txt)

I created a hardlink to original.txt called hardlink.txt (ln hardlink.txt original.txt)

I created a softlink to original.txt called softlink.txt (ln -s softlink.txt original.txt)

Now I will cat both files

Hardlink:
cat hardlink.txt
output: Hello DevOps Hero

Softlink:
cat softlink.txt
output: Hello DevOps Hero

Now I will remove the original file

rm original.txt

Now I will cat both files

Hardlink:
cat hardlink.txt
output: Hello DevOps Hero

Softlink:
cat softlink.txt
output: cat: softlink.txt: No such file or directory
