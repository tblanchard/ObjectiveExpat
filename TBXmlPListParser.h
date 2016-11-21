/*
 See Expat.h for license/copyright.

 This is a sample xml parser that builds a plist based on the xml document.
 See comments below. -tb
*/

#import <Foundation/Foundation.h>
#import <ObjectiveExpat/TBXmlParser.h>

@interface TBXmlPListParser : TBXmlParser
{
    NSMutableArray* _stack;
    NSMutableDictionary *_plist;
    NSMutableString *_cData;
}

-init;
/*
-initWithData:(NSData*)data;
-initWithString:(NSString *)string;
-initWithFile:(NSString *)fileName;
*/

/* these are called by the parser */
-(void)startElement:(NSString*)element withAttributes:(NSDictionary*)attributes;
-(void)endElement:(NSString*)element;
-(void)addCharacterData:(NSString*)data;

/*
-(void)startCDataSection;
-(void)endCDataSection;
-(BOOL)inCDataSection;
*/

/* gives you the plist representation of the xml with character data stored in cdata members */
/* forinstance <foo bar=baz>fooData</foo> turns into {foo = {bar = baz; cdata = fooData; }; } */
/* repeated items are stored in arrays - so for instance
    <object class=Gizmo>
       <attribute name=thingy>thingyValue</attribute>
       <attribute name=doodad>doodadValue</attribute>
    </object>
is represented as
{ object =
    { class = Gizmo;
        attribute = (
                     { name = thingy;
                         cdata = thingyValue;
                     },
                     { name = doodad;
                         cdata = doodadValue;
                     }
                     );
    }
    */

-(NSDictionary*)propertyList;

@end
