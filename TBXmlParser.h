/*
 See licensing/copyright details in ObjectiveExpat.h

 This class is a proxy for an instance of the Expat parser.
 All of the parser callbacks are forwarded to methods that
 you can override to build your own model from the parsed
 document.  Refer to the expat documentation for more details.

 */

#import <Foundation/Foundation.h>

@interface TBXmlParser : NSObject
{
    void* /*XML_Parser*/                _parser;
    NSData*                             _data;
    BOOL                                _standalone;
    NSString*                           _encoding;
    NSString*                           _version;
    BOOL                                _debug;
    BOOL                                _inCDataSection;
    int /*enum XML_ParamEntityParsing*/ _entityParsing;
}

+parserWithURL:(NSURL*)url;

-init;
-initWithData:(NSData*)data;
-initWithString:(NSString *)string;
-initWithFile:(NSString *)fileName;
-initWithURL:(NSURL *)url;

-(void)setStandalone:(BOOL)s;
-(BOOL)standalone;
-(NSString *)encoding;
-(NSString *)version;
-(void)setDebug:(BOOL)d;
-(BOOL)debug;
-(void)setStringToParse:(NSString *)string;
-(void)setDataToParse:(NSData *)data;


-(void)_parseHeader:(NSString*)header;
-(void)dealloc;

-(void)startElement:(NSString*)element withAttributes:(NSDictionary*)attributes;
-(void)endElement:(NSString*)element;

-(void)addCharacterData:(NSString*)data;
- (NSString *)stringWithIgnorableWhitespaceRemoved:(NSString *)inputString;

-(void)processingInstruction:(NSString*) target data:(NSString*)data;

-(void)addComment:(NSString *)data;

-(void)startCDataSection;
-(void)endCDataSection;
-(BOOL)inCDataSection;

-(void)defaultHandler:(NSString*)data;
-(void)defaultHandlerExpand:(NSString*)data;

-(void)unparsedEntityDeclarationForEntity:(NSString*) nsentityName
                                     base:(NSString*) nsbase
                                 systemId:(NSString*) nssystemId
                                 publicId:(NSString*) nspublicId
                             notationName:(NSString*) nsnotationName;

-(void)notationDeclarationForNotation:(NSString*) nsnotationName
                                 base:(NSString*) nsbase
                             systemId:(NSString*) nssystemId
                             publicId:(NSString*) nspublicId;

-(void)externalParsedEntityDeclarationForEntity:(NSString*) nsentityName
                                           base:(NSString*) nsbase
                                       systemId:(NSString*) nssystemId
                                       publicId:(NSString*) nspublicId;

-(void)internalParsedEntityDeclarationForEntity:(NSString*) nsentityName
                                replacementText:(NSString*) replacementText;

-(void)startNamespaceDeclaration:(NSString*) nsprefix uri:(NSString*) nsuri;
-(void)endNamespaceDeclaration:(NSString*) nsprefix;

-(void)startDoctypeDeclaration:(NSString*) nsname 
                         sysid:(NSString*) sid 
                         pubid:(NSString*) pid 
                         hasInternalSubset:(BOOL) yorn;
-(void)endDoctypeDeclaration;

-(BOOL)externalEntityReferenceWithContext:(NSString*) nscontext
                                     base:(NSString*) nsbase
                                 systemId:(NSString*) nssystemId
                                 publicId:(NSString*) nspublicId;


-(BOOL)canProcessStandaloneOnly;

-(void)parseXML;
-(NSException*)tryToParseXML;

-(NSString*)description;

-(int)currentLineNumber;
-(int)currentColumnNumber;

-(void)setParamEntityParsing:(enum XML_ParamEntityParsing) parsing;
-(enum XML_ParamEntityParsing)paramEntityParsing;

-(void*) _xmlParser;

@end
