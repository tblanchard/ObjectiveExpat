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

#import "TBXmlPListParser.h"

@implementation TBXmlPListParser 

- init
{
    [super init];
    _stack = [NSMutableArray array];
    _plist = [NSMutableDictionary dictionary];
    [_stack addObject: _plist];
    return self;
}

/*
-initWithData:(NSData*)data { return [super initWithData: data]; }
-initWithString:(NSString *)string { return [super initWithString: string]; }
-initWithFile:(NSString *)fileName { return [super initWithFile: fileName]; }
*/

-(void)startElement:(NSString*)element withAttributes:(NSDictionary*)attributes
{
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    NSMutableDictionary *parent = [_stack lastObject];
    id value = [parent objectForKey: element];
    _cData = [[NSMutableString new] autorelease];
    
    if (value)
    {
        if ([value isKindOfClass: NSClassFromString(@"NSMutableArray")])
        {
            [value addObject: item];
        }
        else
        {
            NSMutableArray *items = [NSMutableArray arrayWithObject: value];
            [items addObject: item];
            [parent setObject: items forKey: element];
        }
    }
    else [parent setObject: item forKey: element];

    [item addEntriesFromDictionary: attributes];
    [_stack addObject: item];

}

-(void)endElement:(NSString*)element
{
    if(_cData && [_cData length])
    {
        NSMutableDictionary *item = [_stack lastObject];
        [item setObject: _cData forKey: @"cdata"];
        _cData = nil;
    }
    [_stack removeLastObject];
}

-(void)addCharacterData:(NSString*)data
{
    [super addCharacterData: data];
    [_cData appendString: data];
}
/*
-(void)startCDataSection
{
    [super startCDataSection];
    _cData = [[NSMutableString new] autorelease];
}

-(void)endCDataSection
{
    NSMutableDictionary *item = [_stack lastObject];
    [item setObject: data forKey: @"cdata"];
    [super endCDataSection];
}
*/
-(NSDictionary *)propertyList 
{
    if(![_plist count])
    {
        [self parseXML];
    }
    return _plist; 
}

@end
