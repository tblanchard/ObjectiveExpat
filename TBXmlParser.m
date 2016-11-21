/*

 Expat ObjectiveC wrapper for the expat XML Parser.
 Developed by Todd Blanchard <tblanchard@mac.com>

 Please send bug fixes, reports, and enhancement requests to
 the ObjectiveC code to Todd Blanchard.

 Problems with the expat parser library should be reported to
 James Clark <jjc@jclark.com>

 Problems with the IsUTF8Text routine should be reported to the
 mozilla developers at <http://www.mozilla.org>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

 Portions of this file are subject to the Mozilla Public License
 Version 1.1 (the "License"); you may not use this file except in
 compliance with the License. You may obtain a copy of the License at
 http://www.mozilla.org/MPL/

 Software distributed under the License is distributed on an "AS IS"
 basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 License for the specific language governing rights and limitations
 under the License.

 The Original Code is expat.

 The Initial Developer of the Original Code is James Clark.
 Portions created by James Clark are Copyright (C) 1998, 1999
 James Clark. All Rights Reserved.

 Contributors:


*/

#import "TBXmlParser.h"
#import "expat.h"

typedef int32_t int32;

static NSCharacterSet *_xmlWhitespaceCharset = nil;

#define kLeft1BitMask  0x80
#define kLeft2BitsMask 0xC0
#define kLeft3BitsMask 0xE0
#define kLeft4BitsMask 0xF0
#define kLeft5BitsMask 0xF8
#define kLeft6BitsMask 0xFC
#define kLeft7BitsMask 0xFE

#define k2BytesLeadByte kLeft2BitsMask
#define k3BytesLeadByte kLeft3BitsMask
#define k4BytesLeadByte kLeft4BitsMask
#define k5BytesLeadByte kLeft5BitsMask
#define k6BytesLeadByte kLeft6BitsMask
#define kTrialByte      kLeft1BitMask

#define UTF8_1Byte(c) ( 0 == ((c) & kLeft1BitMask))
#define UTF8_2Bytes(c) ( k2BytesLeadByte == ((c) & kLeft3BitsMask))
#define UTF8_3Bytes(c) ( k3BytesLeadByte == ((c) & kLeft4BitsMask))
#define UTF8_4Bytes(c) ( k4BytesLeadByte == ((c) & kLeft5BitsMask))
#define UTF8_5Bytes(c) ( k5BytesLeadByte == ((c) & kLeft6BitsMask))
#define UTF8_6Bytes(c) ( k6BytesLeadByte == ((c) & kLeft7BitsMask))
#define UTF8_ValidTrialByte(c) ( kTrialByte == ((c) & kLeft2BitsMask))

static int IsUTF8Text(const char* utf8, int32 len)
{
   int32 i;
   int32 j;
   int32 clen;
   for(i =0; i < len; i += clen)
   {
      if(UTF8_1Byte(utf8[i]))
      {
        clen = 1;
      } else if(UTF8_2Bytes(utf8[i])) {
        clen = 2;
    /* No enough trail bytes */
        if( (i + clen) > len)
      return FALSE;
    /* 0000 0000 - 0000 007F : should encode in less bytes */
        if(0 ==  (utf8[i] & 0x1E ))
          return FALSE;
      } else if(UTF8_3Bytes(utf8[i])) {
        clen = 3;
    /* No enough trail bytes */
        if( (i + clen) > len)
      return FALSE;
    /* a single Surrogate should not show in 3 bytes UTF8, instead, the pair should be intepreted
       as one single UCS4 char and encoded UTF8 in 4 bytes */
        if((0xED == utf8[i] ) && (0xA0 ==  (utf8[i+1] & 0xA0 ) ))
          return FALSE;
    /* 0000 0000 - 0000 07FF : should encode in less bytes */
        if((0 ==  (utf8[i] & 0x0F )) && (0 ==  (utf8[i+1] & 0x20 ) ))
          return FALSE;
      } else if(UTF8_4Bytes(utf8[i])) {
        clen = 4;
    /* No enough trail bytes */
        if( (i + clen) > len)
      return FALSE;
    /* 0000 0000 - 0000 FFFF : should encode in less bytes */
        if((0 ==  (utf8[i] & 0x07 )) && (0 ==  (utf8[i+1] & 0x30 )) )
          return FALSE;
      } else if(UTF8_5Bytes(utf8[i])) {
        clen = 5;
    /* No enough trail bytes */
        if( (i + clen) > len)
      return FALSE;
    /* 0000 0000 - 001F FFFF : should encode in less bytes */
        if((0 ==  (utf8[i] & 0x03 )) && (0 ==  (utf8[i+1] & 0x38 )) )
          return FALSE;
      } else if(UTF8_6Bytes(utf8[i])) {
        clen = 6;
    /* No enough trail bytes */
        if( (i + clen) > len)
      return FALSE;
    /* 0000 0000 - 03FF FFFF : should encode in less bytes */
        if((0 ==  (utf8[i] & 0x01 )) && (0 ==  (utf8[i+1] & 0x3E )) )
          return FALSE;
      } else {
        return FALSE;
      }
      for(j = 1; j<clen ;j++)
      {
    if(! UTF8_ValidTrialByte(utf8[i+j])) /* Trail bytes invalid */
      return FALSE;
      }
   }
   return TRUE;
}


static void TB_StartElementHandler(void *userData,
                                   const XML_Char *name,
                                   const XML_Char **atts)
{
    id parser = (id) userData;
    NSString *element = [NSString stringWithUTF8String: name];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    while(*atts)
    {
        NSString *key = [NSString stringWithUTF8String: *atts++];
        NSString *value = [NSString stringWithUTF8String: *atts++];

        [attributes setObject: value forKey: key];
    }
    if ([parser debug]) NSLog(@"%@ startElement: %@ withAttributes: %@",[parser class],element,attributes);
    [parser startElement: element withAttributes: attributes];
}

static void TB_EndElementHandler(void *userData,
                                 const XML_Char *name)
{
    id parser = (id) userData;
    NSString *element = [NSString stringWithUTF8String: name];
    if ([parser debug]) NSLog(@"%@ endElement: %@",[parser class],element);
    [parser endElement: element];
}

/* s is not 0 terminated. */
static void TB_CharacterDataHandler(void *userData,
                                    const XML_Char *s,
                                    int len)
{
    // we explictly manage the objects here because we could make 1000's of
    // callbacks before a pool gets released.
    id parser = (id) userData;
    NSData *data = [[NSData alloc] initWithBytes: (void*) s length: len];
    NSMutableString *string = [[NSMutableString alloc] initWithData: data encoding: NSUTF8StringEncoding];

    if ([parser debug]) NSLog(@"%@ addCharacterData: \"%@\"",[parser class],[NSArray arrayWithObject: string]);
    [parser addCharacterData: string];
    [string release];
    [data release];
}

/* target and data are 0 terminated */
static void TB_ProcessingInstructionHandler(void *userData,
                                            const XML_Char *target,
                                            const XML_Char *data)
{
    id parser = (id) userData;
    NSString *t = [NSString stringWithUTF8String: target];
    NSString *d = [NSString stringWithUTF8String: data];

    if ([parser debug]) NSLog(@"%@ processingInstruction: %@ data: %@",[parser class],target,data);
    [parser processingInstruction: t data: d];
}

/* data is 0 terminated */
static void TB_CommentHandler(void *userData, const XML_Char *data)
{
    id parser = (id) userData;
    NSString *s = [NSString stringWithUTF8String: data];
    if ([parser debug]) NSLog(@"%@ addComment: %@",[parser class],s);
    [parser addComment: s];
}

static void TB_StartCdataSectionHandler(void *userData)
{
    id parser = (id) userData;
    if ([parser debug]) NSLog(@"%@ startCDataSection",[parser class]);
    [parser startCDataSection];
}

static void TB_EndCdataSectionHandler(void *userData)
{
    id parser = (id) userData;
    if ([parser debug]) NSLog(@"%@ endCDataSection",[parser class]);
    [parser endCDataSection];
}

/* This is called for any characters in the XML document for
which there is no applicable handler.  This includes both
characters that are part of markup which is of a kind that is
not reported (comments, markup declarations), or characters
that are part of a construct which could be reported but
for which no handler has been supplied. The characters are passed
exactly as they were in the XML document except that
they will be encoded in UTF-8.  Line boundaries are not normalized.
Note that a byte order mark character is not passed to the default handler.
There are no guarantees about how characters are divided between calls
to the default handler: for example, a comment might be split between
multiple calls. */

static void TB_DefaultHandler(void *userData,
                              const XML_Char *s,
                              int len)
{
    id parser = (id) userData;
    NSData *data = [NSData dataWithBytes: (void*) s length: len];
    NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
    if ([parser debug]) NSLog(@"%@ defaultHandler: %@",[parser class],string);
    [parser defaultHandler: string];

}

static void TB_DefaultHandlerExpand(void *userData,
                                    const XML_Char *s,
                                    int len)
{
    id parser = (id) userData;
    NSData *data = [NSData dataWithBytes: (void*) s length: len];
    NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
    if ([parser debug]) NSLog(@"%@ defaultHandlerExpand: %@",[parser class],string);
    [parser defaultHandlerExpand: string];
}

/* This is called for the start of the DOCTYPE declaration when the
name of the DOCTYPE is encountered. */

static void TB_StartDoctypeDeclHandler(void *userData,
                                       const XML_Char *doctypeName,
                                       const XML_Char *sysid,
                                       const XML_Char *pubid,
                                       int has_internal_subset)
{
    id parser = (id) userData;
    NSString *name = [NSString stringWithUTF8String: doctypeName];
    NSString* sid = [NSString stringWithUTF8String: sysid];
    NSString* pid = [NSString stringWithUTF8String: pubid];
    if ([parser debug]) NSLog(@"%@ startDoctypeDeclaration: %@ sysid: %@ pubid: %@ hasInternalSubset: %@" ,[parser class],name,sysid,pubid,(has_internal_subset ? @"YES": @"NO"));
    [parser startDoctypeDeclaration: name sysid: sid pubid: pid hasInternalSubset:(BOOL)has_internal_subset];
}

/* This is called for the start of the DOCTYPE declaration when the
closing > is encountered, but after processing any external subset. */
static void TB_EndDoctypeDeclHandler(void *userData)
{
    id parser = (id) userData;
    if ([parser debug]) NSLog(@"%@ endDoctypeDeclaration",[parser class]);
    [parser endDoctypeDeclaration];
}


/* This is called for a declaration of an unparsed (NDATA)
entity.  The base argument is whatever was set by XML_SetBase.
The entityName, systemId and notationName arguments will never be null.
The other arguments may be. */

#define NSStringOrNil(x) NSString * ns ## x = (x ? [NSString stringWithUTF8String: x] : nil)

static void TB_UnparsedEntityDeclHandler(void *userData,
                                         const XML_Char *entityName,
                                         const XML_Char *base,
                                         const XML_Char *systemId,
                                         const XML_Char *publicId,
                                         const XML_Char *notationName)
{
    id parser = (id) userData;
    NSStringOrNil(entityName);
    NSStringOrNil(base);
    NSStringOrNil(systemId);
    NSStringOrNil(publicId);
    NSStringOrNil(notationName);
    if ([parser debug]) NSLog(@"%@ unparsedEntityDeclarationForEntity: %@ base: %@ systemId: %@ publicId: %@ notationName: %@", [parser class], nsentityName, nsbase, nssystemId, nspublicId, nsnotationName);

    [parser unparsedEntityDeclarationForEntity: nsentityName
                                          base: nsbase
                                      systemId: nssystemId
                                      publicId: nspublicId
                                  notationName: nsnotationName];
}

/* This is called for a declaration of notation.
The base argument is whatever was set by XML_SetBase.
The notationName will never be null.  The other arguments can be. */

static void TB_NotationDeclHandler(void *userData,
                                   const XML_Char *notationName,
                                   const XML_Char *base,
                                   const XML_Char *systemId,
                                   const XML_Char *publicId)
{
    id parser = (id) userData;
    NSStringOrNil(base);
    NSStringOrNil(systemId);
    NSStringOrNil(publicId);
    NSStringOrNil(notationName);
    if ([parser debug]) NSLog(@"%@ notationDeclarationForNotation: %@ base: %@ systemId: %@ publicId: %@", [parser class], nsnotationName, nsbase, nssystemId, nspublicId);

    [parser notationDeclarationForNotation: nsnotationName
                                      base: nsbase
                                  systemId: nssystemId
                                  publicId: nspublicId];
    
}

static void TB_ExternalParsedEntityDeclHandler(void *userData,
                                               const XML_Char *entityName,
                                               const XML_Char *base,
                                               const XML_Char *systemId,
                                               const XML_Char *publicId)
{
    id parser = (id) userData;
    NSStringOrNil(base);
    NSStringOrNil(systemId);
    NSStringOrNil(publicId);
    NSStringOrNil(entityName);
    if ([parser debug]) NSLog(@"%@ externalParsedEntityDeclarationForEntity: %@ base: %@ base: %@ systemId: %@ publicId: %@", [parser class], nsentityName, nsbase, nssystemId, nspublicId);

    [parser externalParsedEntityDeclarationForEntity: nsentityName
                                                base: nsbase
                                            systemId: nssystemId
                                            publicId: nspublicId];

}

static void TB_InternalParsedEntityDeclHandler(void *userData,
                                               const XML_Char *entityName,
                                               const XML_Char *replacementText,
                                               int replacementTextLength)
{
    id parser = (id) userData;
    NSData *data = [NSData dataWithBytes: (void*) replacementText length: replacementTextLength];
    NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
    NSStringOrNil(entityName);

    if ([parser debug]) NSLog(@"%@ internalParsedEntityDeclarationForEntity: %@ replacementText: %@",[parser class],nsentityName,string);
    [parser internalParsedEntityDeclarationForEntity: nsentityName replacementText: string];
}


/* When namespace processing is enabled, these are called once for
each namespace declaration. The call to the start and end element
handlers occur between the calls to the start and end namespace
declaration handlers. For an xmlns attribute, prefix will be null.
For an xmlns="" attribute, uri will be null. */

static void TB_StartNamespaceDeclHandler(void *userData,
                                         const XML_Char *prefix,
                                         const XML_Char *uri)
{
    id parser = (id) userData;
    NSStringOrNil(prefix);
    NSStringOrNil(uri);
    if ([parser debug]) NSLog(@"%@ startNamespaceDeclaration: %@ uri: %@",[parser class],nsprefix,nsuri);
    [parser startNamespaceDeclaration: nsprefix uri: nsuri];
}

static void TB_EndNamespaceDeclHandler(void *userData,
                                       const XML_Char *prefix)
{
    id parser = (id) userData;
    NSStringOrNil(prefix);
    if ([parser debug]) NSLog(@"%@ endNamespaceDeclaration: %@",[parser class],nsprefix);
    [parser endNamespaceDeclaration: nsprefix];
}

/* This is called if the document is not standalone (it has an
external subset or a reference to a parameter entity, but does not
have standalone="yes"). If this handler returns 0, then processing
will not continue, and the parser will return a
XML_ERROR_NOT_STANDALONE error. */

static int TB_NotStandaloneHandler(void *userData)
{
    id parser = (id) userData;
    [parser setStandalone: NO];
    if ([parser debug]) NSLog(@"%@ Document is not standalone",[parser class]); 
    return ![parser canProcessStandaloneOnly];
}

/* This is called for a reference to an external parsed general entity.
The referenced entity is not automatically parsed.
The application can parse it immediately or later using
XML_ExternalEntityParserCreate.
The parser argument is the parser parsing the entity containing the reference;
it can be passed as the parser argument to XML_ExternalEntityParserCreate.
The systemId argument is the system identifier as specified in the entity declaration;
it will not be null.
The base argument is the system identifier that should be used as the base for
resolving systemId if systemId was relative; this is set by XML_SetBase;
it may be null.
The publicId argument is the public identifier as specified in the entity declaration,
or null if none was specified; the whitespace in the public identifier
will have been normalized as required by the XML spec.
The context argument specifies the parsing context in the format
expected by the context argument to
XML_ExternalEntityParserCreate; context is valid only until the handler
returns, so if the referenced entity is to be parsed later, it must be copied.
The handler should return 0 if processing should not continue because of
a fatal error in the handling of the external entity.
In this case the calling parser will return an XML_ERROR_EXTERNAL_ENTITY_HANDLING
error.
Note that unlike other handlers the first argument is the parser, not userData. */

static int TB_ExternalEntityRefHandler(XML_Parser parser,
                                       const XML_Char *context,
                                       const XML_Char *base,
                                       const XML_Char *systemId,
                                       const XML_Char *publicId)
{
    id p = (id) XML_GetUserData(parser);
    NSStringOrNil(context);
    NSStringOrNil(base);
    NSStringOrNil(systemId);
    NSStringOrNil(publicId);
    if([p debug]) NSLog(@"%@ externalEntityReferenceWithContext: %@ base: %@ systemId: %@ publicId: %@",[p class],nscontext,nsbase,nssystemId,nspublicId);
    
    return [p externalEntityReferenceWithContext: nscontext base: nsbase systemId: nssystemId publicId: nspublicId];
}



@implementation TBXmlParser

+ (void)initialize {
    // create this charset once. This is the set of whitespace chars
    // defined by W3C for XML documents. This is different than NSFoundation.
    _xmlWhitespaceCharset = [[NSCharacterSet characterSetWithCharactersInString:@"\r\n\t "] retain];
}

+parserWithURL:(NSURL*)url
{
    return [[[self alloc]initWithURL: url]autorelease];
}

-(void) dealloc
{
    if (_parser)
    {
        XML_ParserFree(_parser);
    }
    [_version release];
    [_data release];

    [super dealloc];
}

-init
{
    if(self = [super init])
    {
        _standalone	= YES;
        _encoding 	= @"UTF-8";
        _version 	= @"1.0";
        _debug = NO;
    }
    return self;
}

-initWithData:(NSData*)data
{
    [self init];
    [self setDataToParse:data];
    return self;
}

- (void)setDataToParse:(NSData *)data {
    NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
    NSArray *items = [string componentsSeparatedByString: @"?>"];
    NSString *header = [items objectAtIndex: 0];
    if ([items count] == 2) {
        [self _parseHeader:header];
    } else if(!IsUTF8Text([data bytes],[data length])) {
        _encoding = @"ISO-8859-1";  
    } 
    _data = [data retain];
}

-initWithString:(NSString *)string
{
    [self init];
    [self setStringToParse:string];
    return self;
}

-(void)setStringToParse:(NSString *)string {
    NSArray *items = [string componentsSeparatedByString: @"?>"];
    NSString *header = [items objectAtIndex: 0];
    if([items count] == 2)
    {
        [self _parseHeader: header];
        _data = [[[items objectAtIndex: 1] dataUsingEncoding: NSUTF8StringEncoding] retain];
    }
    else
    {
        _data = [[string dataUsingEncoding: NSUTF8StringEncoding] retain];
    }
    _encoding = @"UTF-8";
}

-initWithFile:(NSString *)fileName
{
    return [self initWithString: [NSString stringWithContentsOfFile:fileName]];
}

-initWithURL:(NSURL *)url
{
    return [self initWithData:[url resourceDataUsingCache: YES]];
}

-(void)setStandalone:(BOOL)s
{
    if(_debug) NSLog(@"%@ setStandalone %d",[self class],s);
    _standalone = s;
}

-(BOOL)standalone
{
    return _standalone;
}

-(NSString*)encoding
{
    return _encoding;
}

-(NSString *)version
{
    return _version;
}

-(void)setDebug:(BOOL)d
{
    _debug = d;
}

-(BOOL)debug
{
    return _debug;
}

-(void)_parseHeader:(NSString *)header
{
    NSArray *headerItems = [header componentsSeparatedByString:@" "];
    int i;

    for(i = 0; i < [headerItems count]; ++i)
    {
        NSArray *pair = [[headerItems objectAtIndex: i] componentsSeparatedByString: @"="];
        if ([pair count] == 2)
        {
            NSString *value = [pair objectAtIndex: 1];
            NSString *key = [pair objectAtIndex: 0];
            if ([value hasPrefix:@"\""]) value = [value substringFromIndex: 1];
            if ([value hasSuffix:@"\""]) value = [value substringToIndex: [value length]-1];

            if([[key lowercaseString] isEqualToString: @"version"])
            {
                _version = [value retain];
            }
            else if([[key lowercaseString] isEqualToString: @"standalone"])
            {
                _standalone = [[value lowercaseString] isEqualToString: @"yes"];
            }
            else if([[key lowercaseString] isEqualToString: @"encoding"])
            {
                _encoding = [[value uppercaseString] retain];
            }
        }
    }
}

-(void)startElement:(NSString*)element withAttributes:(NSDictionary*)attributes
{
}

-(void)endElement:(NSString*)element
{
}

-(void)addCharacterData:(NSString*)data
{
    // throws out solo whitespace if we're not in a CData section
    if(!_inCDataSection)
    {
        NSString *string = [self stringWithIgnorableWhitespaceRemoved:data];
        if([string length] == 0)
        {
            [((NSMutableString*)data) setString: string];
        }
    }
}

- (NSString *)stringWithIgnorableWhitespaceRemoved:(NSString *)inputString
// returns a string with the returns, newlines, tabs, and spaces removed
// from the beginning and end of the string. According to the W3C XML spec,
// nonvalidating parsers shouldn't do this automatically; this method is
// provided as a convenience to the implementer of subclasses.
{
    NSMutableString *string = [[inputString mutableCopy] autorelease];
    NSRange deleteRange = { 0, 0 };

    while(deleteRange.length < [string length] &&
          [_xmlWhitespaceCharset characterIsMember: [string characterAtIndex: deleteRange.length]])
    {
        ++deleteRange.length;
    }
    [string deleteCharactersInRange: deleteRange];
    //NSLog(@"delete range %d.%d",deleteRange.location, deleteRange.length); 

    deleteRange.length = 0;
    deleteRange.location = [string length];

    while(deleteRange.location > 0 &&
          [_xmlWhitespaceCharset characterIsMember: [string characterAtIndex: deleteRange.location-1]])
    {
        --deleteRange.location;
        ++deleteRange.length;
    }
    [string deleteCharactersInRange: deleteRange];
    //NSLog(@"delete range %d.%d",deleteRange.location, deleteRange.length); 
    return string;
}

-(void)processingInstruction:(NSString*) target data:(NSString*)data
{
}

-(void)addComment:(NSString *)data
{
}

-(void)defaultHandler:(NSString*)data
{
}

-(void)defaultHandlerExpand:(NSString*)data
{
}


-(void)startCDataSection
{
    _inCDataSection = YES;
}

-(void)endCDataSection
{
    _inCDataSection = NO;
}

-(BOOL)inCDataSection
{
    return _inCDataSection;
}

-(void)unparsedEntityDeclarationForEntity:(NSString*) nsentityName
                                     base:(NSString*) nsbase
                                 systemId:(NSString*) nssystemId
                                 publicId:(NSString*) nspublicId
                             notationName:(NSString*) nsnotationName
{
}

-(void)notationDeclarationForNotation:(NSString*) nsnotationName
                                         base:(NSString*) nsbase
                                     systemId:(NSString*) nssystemId
                                     publicId:(NSString*) nspublicId
{
}

-(void)externalParsedEntityDeclarationForEntity:(NSString*) nsentityName
                                           base:(NSString*) nsbase
                                       systemId:(NSString*) nssystemId
                                       publicId:(NSString*) nspublicId
{
}

-(void)internalParsedEntityDeclarationForEntity:(NSString*) nsentityName
                                replacementText:(NSString*) replacementText
{
}

-(void)startNamespaceDeclaration:(NSString*) nsprefix uri:(NSString*) nsuri
{
}

-(void)endNamespaceDeclaration:(NSString*) nsprefix
{
}

-(void)startDoctypeDeclaration:(NSString*) nsname 
                         sysid:(NSString*) sid 
                         pubid:(NSString*) pid 
                         hasInternalSubset:(BOOL) yorn
{
}

-(void)endDoctypeDeclaration
{
}

-(BOOL)externalEntityReferenceWithContext:(NSString*) nscontext
                                     base:(NSString*) nsbase
                                 systemId:(NSString*) nssystemId
                                 publicId:(NSString*) nspublicId
{
    return NO;
}


-(BOOL)canProcessStandaloneOnly
{
    return YES;
}

-(void)parseXML
{
    [[self tryToParseXML] raise];
}

-(NSException*)tryToParseXML
{
    if(!XML_Parse([self _xmlParser],[_data bytes],[_data length],1))
    {
        NSString *errorDescription = [NSString stringWithFormat: @"%@: %s Line: %d Character: %d\n",[self class],
            XML_ErrorString(XML_GetErrorCode([self _xmlParser])),
            XML_GetCurrentLineNumber([self _xmlParser]),
            XML_GetCurrentColumnNumber([self _xmlParser])];

        return [NSException exceptionWithName: @"XMLParseErrorException" reason: errorDescription userInfo: nil];
    }
    return nil;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"<?XML version=\"%@\" standalone=\"%@\" encoding=\"%@\"?>",[self version], ([self standalone]?@"YES":@"NO"),[self encoding]];
}

-(int)currentLineNumber { return XML_GetCurrentLineNumber([self _xmlParser]); }
-(int)currentColumnNumber { return XML_GetCurrentColumnNumber([self _xmlParser]); }

-(void)setParamEntityParsing:(enum XML_ParamEntityParsing) parsing
{
    _entityParsing = parsing;
    if(_parser) XML_SetParamEntityParsing(_parser,_entityParsing);
}

-(enum XML_ParamEntityParsing)paramEntityParsing { return _entityParsing; }

-(void*) _xmlParser
{
    if (!_parser)
    {
        _parser = XML_ParserCreate([_encoding UTF8String]);
        XML_SetUserData(_parser,self);
        XML_SetElementHandler(_parser,TB_StartElementHandler,TB_EndElementHandler);
        XML_SetCharacterDataHandler(_parser,TB_CharacterDataHandler);
        XML_SetProcessingInstructionHandler(_parser,TB_ProcessingInstructionHandler);
        XML_SetCommentHandler(_parser, TB_CommentHandler);
        XML_SetCdataSectionHandler(_parser, TB_StartCdataSectionHandler, TB_EndCdataSectionHandler);
        XML_SetDefaultHandler(_parser, TB_DefaultHandler);
        XML_SetDefaultHandlerExpand(_parser, TB_DefaultHandlerExpand);
        XML_SetUnparsedEntityDeclHandler(_parser, TB_UnparsedEntityDeclHandler);
        XML_SetNotationDeclHandler(_parser, TB_NotationDeclHandler);
        XML_SetNamespaceDeclHandler(_parser, TB_StartNamespaceDeclHandler, TB_EndNamespaceDeclHandler);
        XML_SetNotStandaloneHandler(_parser, TB_NotStandaloneHandler);
        XML_SetExternalEntityRefHandler(_parser, TB_ExternalEntityRefHandler);
        XML_SetDoctypeDeclHandler(_parser, TB_StartDoctypeDeclHandler, TB_EndDoctypeDeclHandler);
        //Removed sometime after expat v1.2
        //XML_SetExternalParsedEntityDeclHandler(_parser, TB_ExternalParsedEntityDeclHandler);
        //XML_SetInternalParsedEntityDeclHandler(_parser, TB_InternalParsedEntityDeclHandler);
        XML_SetParamEntityParsing(_parser,_entityParsing);
    }
    return _parser;
}

@end
