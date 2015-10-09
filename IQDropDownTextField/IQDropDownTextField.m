//
//  IQDropDownTextField.m
// https://github.com/hackiftekhar/IQDropDownTextField
// Copyright (c) 2013-15 Iftekhar Qurashi.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "IQDropDownTextField.h"

#ifndef NSFoundationVersionNumber_iOS_5_1
#define NSTextAlignmentCenter UITextAlignmentCenter
#endif


@interface IQDropDownTextField () <UIPickerViewDelegate, UIPickerViewDataSource>
{
    NSArray *_ItemListsInternal;
    NSArray *_MonthDayListsInternal;
    
    UIView* _keyboradView;
    UIButton* _doneButton;
}

@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIDatePicker *timePicker;
@property (nonatomic, strong) NSDateFormatter *dropDownDateFormatter;
@property (nonatomic, strong) NSDateFormatter *dropDownTimeFormatter;

- (void)dateChanged:(UIDatePicker *)dPicker;
- (void)timeChanged:(UIDatePicker *)tPicker;

@end

@implementation IQDropDownTextField

@synthesize dropDownMode = _dropDownMode;
@synthesize itemList = _itemList;
@synthesize selectedItem = _selectedItem;
@synthesize isOptionalDropDown = _isOptionalDropDown;
@synthesize datePickerMode = _datePickerMode;
@synthesize minimumDate = _minimumDate;
@synthesize maximumDate = _maximumDate;
@dynamic delegate;

@synthesize pickerView = _pickerView, datePicker = _datePicker, timePicker = _timePicker;
@synthesize dropDownDateFormatter,dropDownTimeFormatter;
@synthesize dateFormatter, timeFormatter;

#pragma mark - NSObject

- (void)dealloc {
    [self.pickerView setDelegate:nil];
    [self.pickerView setDataSource:nil];
}

#pragma mark - Initialization

- (void)initialize
{
    [self setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    
    self.optionalItemLabel = @"選択してください";
    
    
    
    _keyboradView = [[UIView alloc] init];
    [_keyboradView setBackgroundColor:[UIColor colorWithRed:0.78 green:0.80 blue:0.83 alpha:1]];
    
    UIView* toolView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, 44)];
    [toolView setBackgroundColor:[UIColor colorWithRed:0.93 green:0.93 blue:0.94 alpha:1]];
    [_keyboradView addSubview:toolView];
    
    UIView* lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, 1.0 / [[UIScreen mainScreen] scale])];
    lineView.backgroundColor = [UIColor lightGrayColor];
    [_keyboradView addSubview:lineView];
    
    
    _doneButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    [_doneButton setTitle:@"完了" forState:UIControlStateNormal];
    [_doneButton setTintColor:[UIColor blackColor]];
    [_doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_doneButton addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [_keyboradView addSubview:_doneButton];
    
    if ([[[self class] appearance] dateFormatter])
    {
        self.dropDownDateFormatter = [[NSDateFormatter alloc] init];
        self.dropDownDateFormatter = [[[self class] appearance] dateFormatter];
    }
    else
    {
        self.dropDownDateFormatter = [[NSDateFormatter alloc] init];
        //        [self.dropDownDateFormatter setDateFormat:@"dd MMM yyyy"];
        [self.dropDownDateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dropDownDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    }
    
    self.dropDownTimeFormatter = [[NSDateFormatter alloc] init];
    [self.dropDownTimeFormatter setDateStyle:NSDateFormatterNoStyle];
    [self.dropDownTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    [self setDropDownMode:IQDropDownModeTextPicker];
    [self setIsOptionalDropDown:YES];
    
    
    NSMutableArray* monthList = @[].mutableCopy;
    for (int i = 1; i <= 12; i++) {
        [monthList addObject:[NSString stringWithFormat:@"%d月", i]];
    }
    NSMutableArray* dayList = @[].mutableCopy;
    for (int i = 1; i <= 31; i++) {
        [dayList addObject:[NSString stringWithFormat:@"%d日", i]];
    }
    _MonthDayListsInternal = @[ monthList, dayList ];
    
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initialize];
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self initialize];
}

- (void)close:(id)sender {
    [self resignFirstResponder];
}

#pragma mark - UITextField overrides

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    return CGRectZero;
}

#pragma mark - UIPickerView data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return _dropDownMode == IQDropDownModeTextPicker ? 1 : 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (_dropDownMode == IQDropDownModeTextPicker) {
        return _ItemListsInternal.count;
    }
    return ((NSArray*)_MonthDayListsInternal[component]).count;
}

#pragma mark UIPickerView delegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *labelText = [[UILabel alloc] init];
    [labelText setTextAlignment:NSTextAlignmentCenter];
    [labelText setAdjustsFontSizeToFitWidth:YES];
    labelText.backgroundColor = [UIColor clearColor];
    
    if (_dropDownMode == IQDropDownModeTextPicker && self.isOptionalDropDown && row == 0)
    {
        labelText.font = [UIFont boldSystemFontOfSize:18.0];
        labelText.textColor = [UIColor lightGrayColor];
    }
    else
    {
        labelText.font = [UIFont boldSystemFontOfSize:18.0];
        labelText.textColor = [UIColor blackColor];
    }
    if (_dropDownMode == IQDropDownModeTextPicker) {
        [labelText setText:[_ItemListsInternal objectAtIndex:row]];
    } else {
        [labelText setText:_MonthDayListsInternal[component][row]];
    }
    return labelText;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (_dropDownMode == IQDropDownModeTextPicker) {
        [self setSelectedItem:[_ItemListsInternal objectAtIndex:row]];
    } else {
        int month = (int)[pickerView selectedRowInComponent:0] + 1;
        int day   = (int)[pickerView selectedRowInComponent:1] + 1;
        
        NSString* str;
        if (month == 2 && day > 29) {
            str = [NSString stringWithFormat:@"%d/%d", month, 29];
        } else if ((month == 4 || month == 6 || month == 9 || month == 11) && day > 30) {
            str = [NSString stringWithFormat:@"%d/%d", month, 30];
        } else {
            str = [NSString stringWithFormat:@"%d/%d", month, day];
        }
        
        [self setSelectedItem:str];
        
    }
}

#pragma mark - UIDatePicker delegate

- (void)dateChanged:(UIDatePicker *)dPicker
{
    [self setSelectedItem:[self.dropDownDateFormatter stringFromDate:dPicker.date]];
}

- (void)timeChanged:(UIDatePicker *)tPicker
{
    [self setSelectedItem:[self.dropDownTimeFormatter stringFromDate:tPicker.date]];
}

#pragma mark - Selected Row

- (NSInteger)selectedRow
{
    if (self.isOptionalDropDown)
    {
        return [self.pickerView selectedRowInComponent:0]-1;
    }
    else
    {
        return [self.pickerView selectedRowInComponent:0];
    }
}

-(void)setSelectedRow:(NSInteger)selectedRow
{
    [self setSelectedRow:selectedRow animated:NO];
}

- (void)setSelectedRow:(NSInteger)row animated:(BOOL)animated
{
    if (row < [_ItemListsInternal count])
    {
        if (self.isOptionalDropDown && row == 0)
        {
            self.text = @"";
        }
        else
        {
            self.text = [_ItemListsInternal objectAtIndex:row];
        }
        
        [self.pickerView selectRow:row inComponent:0 animated:animated];
    }
}

#pragma mark - Setters

- (void)setInputPickerView:(UIView*)picker
{
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    CGSize pickerSize = picker.bounds.size;
    CGSize buttonSize = _doneButton.bounds.size;
    _keyboradView.frame = CGRectMake(0,
                                     0,
                                     screenWidth,
                                     buttonSize.height + pickerSize.height);
    _doneButton.frame   = CGRectMake(screenWidth - buttonSize.width,
                                     0,
                                     buttonSize.width,
                                     buttonSize.height);
    picker.frame        = CGRectMake(0,
                                     buttonSize.height,
                                     screenWidth,
                                     buttonSize.height + pickerSize.height);
    
    [_keyboradView addSubview:picker];
    self.inputView = _keyboradView;
}

- (void)setDropDownMode:(IQDropDownMode)dropDownMode
{
    _dropDownMode = dropDownMode;
    
    switch (_dropDownMode)
    {
        case IQDropDownModeTextPicker:
        {
            [self setInputPickerView:self.pickerView];
            [self setSelectedRow:self.selectedRow animated:YES];
        }
            break;
        case IQDropDownModeDatePicker:
        {
            [self setInputPickerView:self.datePicker];
            
            if (self.isOptionalDropDown == NO)
            {
                [self setDate:self.datePicker.date];
            }
        }
            break;
        case IQDropDownModeTimePicker:
        {
            [self setInputPickerView:self.timePicker];
            
            if (self.isOptionalDropDown == NO)
            {
                [self setDate:self.timePicker.date];
            }
        }
            break;
        case IQDropDownModeMonthDayPicker:
        {
            [self.pickerView reloadAllComponents];
            [self setInputPickerView:self.pickerView];
            //            [self setSelectedRow:self.selectedRow animated:YES];
            
        }
        default:
            break;
    }
}

- (void)setItemList:(NSArray *)itemList
{
    _itemList = itemList;
    
    //Refreshing pickerView
    [self setIsOptionalDropDown:_isOptionalDropDown];
    
    [self setSelectedRow:self.selectedRow];
}

-(NSDate *)date
{
    switch (self.dropDownMode)
    {
        case IQDropDownModeDatePicker:  return  ([self.text length] || self.isOptionalDropDown)  ?   [self.datePicker.date copy]    :   nil;    break;
        case IQDropDownModeTimePicker:  return  ([self.text length] || self.isOptionalDropDown)  ?   [self.timePicker.date copy]    :   nil;    break;
        default:                        return  nil;                     break;
    }
}

-(void)setDate:(NSDate *)date
{
    [self setDate:date animated:NO];
}

- (void)setDate:(NSDate *)date animated:(BOOL)animated
{
    switch (_dropDownMode)
    {
        case IQDropDownModeDatePicker:
            [self setSelectedItem:[self.dropDownDateFormatter stringFromDate:date] animated:animated];
            break;
        case IQDropDownModeTimePicker:
            [self setSelectedItem:[self.dropDownTimeFormatter stringFromDate:date] animated:animated];
            break;
        default:
            break;
    }
}

- (void)setDateFormatter:(NSDateFormatter *)userDateFormatter
{
    self.dropDownDateFormatter = userDateFormatter;
    [self.datePicker setLocale:self.dropDownDateFormatter.locale];
}

- (void)setTimeFormatter:(NSDateFormatter *)userTimeFormatter
{
    self.dropDownTimeFormatter = userTimeFormatter;
    [self.timePicker setLocale:self.dropDownTimeFormatter.locale];
}

-(void)setSelectedItem:(NSString *)selectedItem
{
    [self setSelectedItem:selectedItem animated:NO];
}

-(void)setSelectedItem:(NSString *)selectedItem animated:(BOOL)animated
{
    switch (_dropDownMode)
    {
        case IQDropDownModeTextPicker:
            if ([_ItemListsInternal containsObject:selectedItem])
            {
                _selectedItem = selectedItem;
                
                [self setSelectedRow:[_ItemListsInternal indexOfObject:selectedItem] animated:animated];
                
                if ([self.delegate respondsToSelector:@selector(textField:didSelectItem:)])
                    [self.delegate textField:self didSelectItem:_selectedItem];
            }
            break;
        case IQDropDownModeDatePicker:
        {
            NSDate *date = [self.dropDownDateFormatter dateFromString:selectedItem];
            if (date)
            {
                _selectedItem = selectedItem;
                self.text = selectedItem;
                [self.datePicker setDate:date animated:animated];
                
                if ([self.delegate respondsToSelector:@selector(textField:didSelectItem:)])
                    [self.delegate textField:self didSelectItem:_selectedItem];
            }
            else if ([selectedItem length])
            {
                NSLog(@"Invalid date or date format:%@",selectedItem);
            }
            break;
        }
        case IQDropDownModeTimePicker:
        {
            NSDate *date = [self.dropDownTimeFormatter dateFromString:selectedItem];
            if (date)
            {
                _selectedItem = selectedItem;
                self.text = selectedItem;
                [self.timePicker setDate:date animated:animated];
                
                if ([self.delegate respondsToSelector:@selector(textField:didSelectItem:)])
                    [self.delegate textField:self didSelectItem:_selectedItem];
            }
            else if([selectedItem length])
            {
                NSLog(@"Invalid time or time format:%@",selectedItem);
            }
            break;
        }
        case IQDropDownModeMonthDayPicker:
        {
            _selectedItem = selectedItem;
            
            self.text = selectedItem;
            
            NSArray* nums = [selectedItem componentsSeparatedByString:@"/"];
            if (nums.count == 2) {
                NSString* month = nums[0];
                NSString* day   = nums[1];
                [self.pickerView selectRow:month.intValue - 1 inComponent:0 animated:NO];
                [self.pickerView selectRow:day.intValue   - 1 inComponent:1 animated:NO];
            }
            
            if ([self.delegate respondsToSelector:@selector(textField:didSelectItem:)])
                [self.delegate textField:self didSelectItem:_selectedItem];
        }
    }
}

- (void)setDatePickerMode:(UIDatePickerMode)datePickerMode
{
    if (_dropDownMode == IQDropDownModeDatePicker)
    {
        _datePickerMode = datePickerMode;
        [self.datePicker setDatePickerMode:datePickerMode];
        
        switch (datePickerMode) {
            case UIDatePickerModeCountDownTimer:
                [self.dropDownDateFormatter setDateStyle:NSDateFormatterNoStyle];
                [self.dropDownDateFormatter setTimeStyle:NSDateFormatterNoStyle];
                break;
            case UIDatePickerModeDate:
                [self.dropDownDateFormatter setDateStyle:NSDateFormatterShortStyle];
                [self.dropDownDateFormatter setTimeStyle:NSDateFormatterNoStyle];
                break;
            case UIDatePickerModeTime:
                [self.dropDownDateFormatter setDateStyle:NSDateFormatterNoStyle];
                [self.dropDownDateFormatter setTimeStyle:NSDateFormatterShortStyle];
                break;
            case UIDatePickerModeDateAndTime:
                [self.dropDownDateFormatter setDateStyle:NSDateFormatterShortStyle];
                [self.dropDownDateFormatter setTimeStyle:NSDateFormatterShortStyle];
                break;
        }
    }
}

-(void)setMinimumDate:(NSDate *)minimumDate
{
    _minimumDate = minimumDate;
    
    self.datePicker.minimumDate = minimumDate;
    self.timePicker.minimumDate = minimumDate;
}

-(void)setMaximumDate:(NSDate *)maximumDate
{
    _maximumDate = maximumDate;
    
    self.datePicker.maximumDate = maximumDate;
    self.timePicker.maximumDate = maximumDate;
}

- (void) setOptionalItemLabel:(NSString *)optionalItemLabel
{
    _optionalItemLabel = [optionalItemLabel copy];
    
    [self _updateOptionsList];
}

-(void)setIsOptionalDropDown:(BOOL)isOptionalDropDown
{
    _isOptionalDropDown = isOptionalDropDown;
    
    [self _updateOptionsList];
}

- (void) _updateOptionsList {
    if (_isOptionalDropDown)
    {
        NSArray *array = [NSArray arrayWithObject:self.optionalItemLabel];
        _ItemListsInternal = [array arrayByAddingObjectsFromArray:_itemList];
        [self.pickerView reloadAllComponents];
    }
    else
    {
        _ItemListsInternal = [_itemList copy];
        
        switch (self.dropDownMode)
        {
            case IQDropDownModeDatePicker:
            {
                [self setDate:self.datePicker.date];
            }
                break;
            case IQDropDownModeTimePicker:
            {
                [self setDate:self.timePicker.date];
            }
                break;
                
            case IQDropDownModeTextPicker:
            case IQDropDownModeMonthDayPicker:
            {
                [self.pickerView reloadAllComponents];
            }
            default:
                break;
        }
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:) || action == @selector(cut:))
        return NO;
    
    
    return [super canPerformAction:action withSender:sender];
}

#pragma mark - Getter

- (UIPickerView *) pickerView {
    if (!_pickerView)
    {
        _pickerView = [[UIPickerView alloc] init];
        [_pickerView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
        [_pickerView setShowsSelectionIndicator:YES];
        [_pickerView setDelegate:self];
        [_pickerView setDataSource:self];
    }
    return _pickerView;
}

- (UIDatePicker *) timePicker
{
    if (!_timePicker)
    {
        _timePicker = [[UIDatePicker alloc] init];
        _timePicker = [[UIDatePicker alloc] init];
        [_timePicker setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
        [_timePicker setDatePickerMode:UIDatePickerModeTime];
        [_timePicker addTarget:self action:@selector(timeChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _timePicker;
}

- (UIDatePicker *) datePicker
{
    if (!_datePicker)
    {
        _datePicker = [[UIDatePicker alloc] init];
        [_datePicker setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
        [_datePicker setDatePickerMode:UIDatePickerModeDate];
        [_datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _datePicker;
}


-(NSDateComponents *)dateComponents
{
    return [[NSCalendar currentCalendar] components:kCFCalendarUnitDay | kCFCalendarUnitMonth | kCFCalendarUnitYear fromDate:self.date];
}

- (NSInteger)year   {   return [[self dateComponents] year];    }
- (NSInteger)month  {   return [[self dateComponents] month];   }
- (NSInteger)day    {   return [[self dateComponents] day];     }
- (NSInteger)hour   {   return [[self dateComponents] hour];    }
- (NSInteger)minute {   return [[self dateComponents] minute];  }
- (NSInteger)second {   return [[self dateComponents] second];  }

@end
