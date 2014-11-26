//
//  genPdf.m
//  Mayo-ipad
//
//  Created Anirudh Adibhatla on 11/23/14.
//  Copyright (c) 2014 rishabh srivastava. All rights reserved.
//

#import "genPdf.h"

@implementation genPdf
const int NUM_OF_Q_IN_MAIN_PAGE=5;
const int NUM_OF_Q_IN_SEC_PAGE=9;
-(void)start:(NSDictionary *)dict image:(UIImage*)img{
    NSMutableArray *pageBreaks=[self getPageBreaks:[dict count]];
    //NSLog(@"%d",numOfPages);
    NSMutableArray *arrayOfViews=[[NSMutableArray alloc]init];
    arrayOfViews=[self getViews:dict pageBreaksArray:pageBreaks image:img];
    self.pdfFileName=[self createPDFfromUIViews:arrayOfViews fileName:@"test.pdf"];
    //[self deletePdf:fileName];
}

-(NSMutableArray*)getPageBreaks:(int)numOfQuestions{
    NSMutableArray *pageBreaks=[NSMutableArray array];
    [pageBreaks addObject:[NSNumber numberWithInt:NUM_OF_Q_IN_MAIN_PAGE-1]];
    int count=NUM_OF_Q_IN_MAIN_PAGE;
    while (count<numOfQuestions) {
        count+=NUM_OF_Q_IN_SEC_PAGE;
        [pageBreaks addObject:[NSNumber numberWithInt:count-1]];
    }
    [pageBreaks replaceObjectAtIndex:[pageBreaks count]-1 withObject:[NSNumber numberWithInt:numOfQuestions-1]];
    return pageBreaks;
}


-(NSMutableArray*)getViews:(NSDictionary *)dict pageBreaksArray:(NSMutableArray *) pageBreaks image:(UIImage*)img{
    NSMutableArray *arrayOfViews=[[NSMutableArray alloc]init];
    int currStart,currEnd;
    for (int i=0; i<[pageBreaks count]; i++) {
        if(i==0){
            [arrayOfViews addObject:[self genView:dict startQuestion:0 endQuestion:[[pageBreaks objectAtIndex:i] integerValue] template:@"mainPageTemplate" image:img]];
        }
        else{
            currStart=[[pageBreaks objectAtIndex:i-1] integerValue]+1;
            currEnd=[[pageBreaks objectAtIndex:i] integerValue];
            [arrayOfViews addObject:[self genView:dict startQuestion:currStart endQuestion:currEnd template:@"secondPageTemplate" image:img]];
        }
    }
    
    //check if remarks are present
    if([dict objectForKey:@"remarks"]&&![[dict objectForKey:@"remarks"] isEqual:@""]){
        UIView *pageTemplate=[self loadTemplate:@"remarksView"];
        UILabel *remarksLabel=(UILabel*)[pageTemplate viewWithTag:100];
        remarksLabel.text=[dict objectForKey:@"remarks"];
        [arrayOfViews addObject:pageTemplate];
    }
    return arrayOfViews;
}

-(UIView*)genView:(NSDictionary *)dict startQuestion:(int) startQ endQuestion:(int) endQ template:(NSString *)templateName image:(UIImage*)img{
    self.numOfQinDict=[dict count];
    UIView *pageTemplate=[self loadTemplate:templateName];
    NSArray*keys=[dict allKeys];
    UILabel *surveyLabel;
    UILabel *tempLabel;
    UIView *tempView;
    int correction=0;
    for(int i=startQ;i<=endQ;i++){
        if([keys[i] isEqual:@"remarks"]){
            correction=1;
            continue;
        }
        surveyLabel=(UILabel *)[pageTemplate viewWithTag:100+(i-startQ-correction)];
        if((100+(i-startQ-correction))%2==0){
            [[surveyLabel layer] setBorderWidth:0.5];
        }
        tempView=[self loadTemplate:@"qaView"];
        tempLabel=(UILabel*)[tempView viewWithTag:200];
        tempLabel.text=[[NSString stringWithFormat:@" %d) ",i+1-correction] stringByAppendingString:keys[i]];
        tempLabel=(UILabel*)[tempView viewWithTag:201];
        tempLabel.text=[dict objectForKey:keys[i]];
        [surveyLabel insertSubview:tempView atIndex:0];
    }
    
    //check if image exists
    if (img!=nil) {
        UIImageView *imgView=(UIImageView*)[pageTemplate viewWithTag:1000];
        [imgView setImage:img];
    }
    return pageTemplate;
}

/*
 -(void)genPNG:(NSDictionary *)dict{
 self.numOfQinDict=[dict count];
 UIView *mainPageTemplate=[self loadTemplate:@"mainPageTemplate"];
 NSArray*keys=[self.dict allKeys];
 UILabel *surveyLabel;
 UILabel *tempLabel;
 UIView *tempView;
 for(int i=0;i<NUM_OF_Q_IN_MAIN_PAGE;i++){
 //temp=[NSString stringWithFormat: @"%@\n%@\n",keys[i],[dict objectForKey:keys[i]]];
 //final=[final stringByAppendingString:temp];
 surveyLabel=(UILabel *)[mainPageTemplate viewWithTag:100+i];
 tempView=[self loadTemplate:@"qaView"];
 tempLabel=(UILabel*)[tempView viewWithTag:200];
 tempLabel.text=[[NSString stringWithFormat:@" %d) ",i+1] stringByAppendingString:keys[i]];
 tempLabel=(UILabel*)[tempView viewWithTag:201];
 tempLabel.text=[dict objectForKey:keys[i]];
 [surveyLabel insertSubview:tempView atIndex:0];
 }
 [self savePNG:mainPageTemplate fileName:@"/Users/Sachin/Desktop/mainPage1.png"];
 }
 */
-(void)savePNG:(UIView *)currTemplate fileName:(NSString *)fName{
    UIGraphicsBeginImageContext(currTemplate.bounds.size);
    [currTemplate.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:fName atomically:YES];
}


-(NSString*)createPDFfromUIViews:(NSMutableArray*)arrayOfViews fileName:(NSString *)aFilename
{
    // Creates a mutable data object for updating with binary data, like a byte array
    NSMutableData *pdfData = [NSMutableData data];
    UIView *aView=[arrayOfViews objectAtIndex:0];
    // Points the pdf converter to the mutable data object and to the UIView to be converted
    UIGraphicsBeginPDFContextToData(pdfData, aView.bounds, nil);
    UIGraphicsBeginPDFPage();
    CGContextRef pdfContext = UIGraphicsGetCurrentContext();
    
    
    // draws rect to the view and thus this is captured by UIGraphicsBeginPDFContextToData
    for (int i=0; i<[arrayOfViews count]; i++) {
        aView=[arrayOfViews objectAtIndex:i];
        [aView.layer renderInContext:pdfContext];
        if (i<[arrayOfViews count]-1) {
            UIGraphicsBeginPDFPage();
        }
    }
    
    
    // remove PDF rendering context
    UIGraphicsEndPDFContext();
    
    // Retrieves the document directories from the iOS device
    NSArray* documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    
    NSString* documentDirectory = [documentDirectories objectAtIndex:0];
    NSString* documentDirectoryFilename = [documentDirectory stringByAppendingPathComponent:aFilename];
    
    // instructs the mutable data object to write its context to a file on disk
    [pdfData writeToFile:documentDirectoryFilename atomically:YES];
    NSLog(@"documentDirectoryFileName: %@",documentDirectoryFilename);
    return documentDirectoryFilename;
}

-(void)deletePdf:(NSString *)fileName{
    NSFileManager *filemgr;
    filemgr = [NSFileManager defaultManager];
    NSError *error;
    
    BOOL success = [filemgr removeItemAtPath:fileName error:&error];
    
    if (success) {
        printf("Deleted");
    }
    else
    {
        printf("Not Deleted");
    }
    
}

//A function that will load a given template and return the corresponding UIView
- (UIView *)loadTemplate:(NSString *)templateName
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:templateName owner:self options:nil];
    for (id view in nib) {
        if ([view isKindOfClass: [UIView class]]) {
            return view;
        }
    }
    return nil;
}


@end
