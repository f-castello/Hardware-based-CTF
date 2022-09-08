import os
import cherrypy
import random
import string
import json
import logging
from CipherDriver import CipherDriver
from pynq import Overlay

port = 8080
PATH = os.path.abspath(os.path.dirname("./"))

class Root(object): 

        @cherrypy.expose
        def __init__(self):
                self.overlay = Overlay("../Board_Files/gen/design_1.bit") 


        @cherrypy.expose
        @cherrypy.tools.json_out()
        @cherrypy.tools.json_in()
        def ciphe2(self):  
                # Parse incoming data
                input_json = cherrypy.request.json
                message = input_json["message"]
                messageFormat = input_json["messageFormat"]
                seed = input_json["seed"]
                seedFormat = input_json["seedFormat"]

                logging.warning("inside chipe2")
                return  self.overlay.myip_0.ciphe(message,messageFormat,seed,seedFormat)


         
if __name__=="__main__":
        cherrypy.server.socket_host = "0.0.0.0"
        cherrypy.quickstart(Root(), '/', config={
                
                '/': {
                    'tools.staticdir.on': True,
                    'tools.staticdir.dir': PATH,
                  'tools.staticdir.index': 'webpage.html',
                  },
          })
        

