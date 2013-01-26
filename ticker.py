import pycurl
import cStringIO

exchange_url ='https://mtgox.com/code/data/ticker.php'
item_number = 6 
final = []
def cut_the_crap(stuff):
	i = 0
	while i < item_number: 
	    firstquote = stuff.find('"')	
	    secondquote = stuff.find('"',firstquote+1)
	    keeper = stuff[firstquote+1:secondquote]
	    stuff = stuff[secondquote+1:]
	    final.append(keeper)
	    i = i + 1
	return final 

buf = cStringIO.StringIO()
c = pycurl.Curl()
c.setopt(c.URL, exchange_url)
c.setopt(c.WRITEFUNCTION, buf.write)
c.perform()

latest = buf.getvalue()

cut_the_crap(latest)

last = final[0] + ':$' + final[1] + ' '
bid = final[2] + ':$' + final[3] + ' '
ask = final[4] + ':$' + final[5] 

print last 
print bid
print ask    

buf.close()
