#include "menu.h"
#include "driver.h"
#include "json.h"

@implementation MenuItem
- (void)setupOnClick:(NSString *)selector {
  if (!self.enabled) {
    return;
  }

  if (self.hasSubmenu) {
    self.action = @selector(submenuAction:);
    return;
  }

  if (selector != nil && selector.length > 0) {
    self.action = NSSelectorFromString(selector);
    return;
  }

  if (self.onClick == nil || self.onClick.length == 0) {
    return;
  }

  self.target = self;
  self.action = @selector(clicked:);
}

- (void)clicked:(id)sender {
  NSMutableDictionary<NSString *, id> *mapping =
      [[NSMutableDictionary alloc] init];
  mapping[@"compo-id"] = self.compoID;
  mapping[@"target"] = self.onClick;
  mapping[@"json-value"] = @"{}";

  Driver *driver = [Driver current];
  [driver.golang
      request:[NSString stringWithFormat:@"/menu/callback?id=%@", self.elemID]
      payload:[JSONEncoder encodeObject:mapping]];
}

- (void)setupKeys:(NSString *)keys {
  if (keys == nil || keys.length == 0) {
    return;
  }

  keys = [keys lowercaseString];

  NSArray *keyArray = [keys componentsSeparatedByString:@"+"];
  self.keyEquivalentModifierMask = 0;

  for (NSString *key in keyArray) {
    if ([key isEqual:@"cmd"] || [key isEqual:@"cmdorctrl"]) {
      self.keyEquivalentModifierMask |= NSEventModifierFlagCommand;
    } else if ([key isEqual:@"ctrl"]) {
      self.keyEquivalentModifierMask |= NSEventModifierFlagControl;
    } else if ([key isEqual:@"alt"]) {
      self.keyEquivalentModifierMask |= NSEventModifierFlagOption;
    } else if ([key isEqual:@"shift"]) {
      self.keyEquivalentModifierMask |= NSEventModifierFlagShift;
    } else if ([key isEqual:@"fn"]) {
      self.keyEquivalentModifierMask |= NSEventModifierFlagFunction;
    } else if ([key isEqual:@""]) {
      self.keyEquivalent = @"+";
    } else {
      self.keyEquivalent = key;
    }
  }
}
@end

@implementation MenuContainer
- (instancetype)init {
  self = [super init];
  self.children = [[NSMutableArray alloc] init];
  return self;
}

- (void)addChild:(MenuItem *)child {
  [self.children addObject:child];

  if (child.separator != nil) {
    [self addItem:child.separator];
    child.menu = self;
    return;
  }

  [self addItem:child];
}
@end

@implementation Menu
+ (bridge_result)newMenu:(NSURLComponents *)url payload:(NSString *)payload {
  NSString *ID = [url queryValue:@"id"];

  dispatch_async(dispatch_get_main_queue(), ^{
    Menu *menu = [[Menu alloc] init];
    menu.ID = ID;

    // Registering menu.
    Driver *driver = [Driver current];
    driver.elements[ID] = menu;
  });
  return make_bridge_result(nil, nil);
}

+ (bridge_result)load:(NSURLComponents *)url payload:(NSString *)payload {
  NSString *ID = [url queryValue:@"id"];
  NSString *returnID = [url queryValue:@"return-id"];
  NSDictionary *content = [JSONDecoder decodeObject:payload];

  dispatch_async(dispatch_get_main_queue(), ^{
    Driver *driver = [Driver current];
    Menu *menu = driver.elements[ID];
    NSString *err = nil;

    @try {
      menu.root = [menu newContainer:content];
      menu.root.delegate = menu;
    } @catch (NSException *exception) {
      err = exception.reason;
    }
  });
  return make_bridge_result(nil, nil);
}

+ (bridge_result)render:(NSURLComponents *)url payload:(NSString *)payload {
  NSLog(@"should render");
  return make_bridge_result(nil, nil);
}

+ (bridge_result)renderAttributes:(NSURLComponents *)url
                          payload:(NSString *)payload {
  NSLog(@"should render attributes");
  return make_bridge_result(nil, nil);
}

- (MenuContainer *)newContainer:(NSDictionary *)map {
  NSString *name = map[@"name"];
  NSString *ID = map[@"id"];
  NSString *compoID = map[@"compo-id"];
  NSDictionary *attributes = map[@"attributes"];
  NSString *label = @"";
  NSArray *children = map[@"children"];

  if (attributes != (id)[NSNull null]) {
    label = attributes[@"label"];
    label = label == nil ? @"" : label;
  }

  if (![name isEqual:@"menu"]) {
    @throw [NSException
        exceptionWithName:@"ErrMenuContainer"
                   reason:[NSString
                              stringWithFormat:
                                  @"cannot create a MenuContainer from a %@",
                                  name]
                 userInfo:nil];
  }

  MenuContainer *container = [[MenuContainer alloc] initWithTitle:label];
  container.ID = ID;
  container.compoID = compoID;

  if (children != (id)[NSNull null]) {
    for (NSDictionary *child in children) {
      NSString *childName = child[@"name"];
      MenuItem *item = [self newItem:child];

      if ([childName isEqual:@"menu"]) {
        item.submenu = [self newContainer:child];
      }

      [container addChild:item];
    }
  }
  return container;
}

- (MenuItem *)newItem:(NSDictionary *)map {
  MenuItem *item = nil;
  NSString *name = map[@"name"];
  NSString *ID = map[@"id"];
  NSString *compoID = map[@"compo-id"];
  NSDictionary *attributes = map[@"attributes"];
  NSString *label = @"";
  NSString *disabled = nil;
  NSString *separator = nil;
  NSString *selector = nil;
  NSString *onClick = nil;
  NSString *keys = nil;

  if (attributes != (id)[NSNull null]) {
    label = attributes[@"label"];
    label = label == nil ? @"" : label;
    disabled = attributes[@"disabled"];
    separator = attributes[@"separator"];
    selector = attributes[@"selector"];
    onClick = attributes[@"onclick"];
    keys = attributes[@"keys"];
  }

  if (![name isEqual:@"menuitem"] && ![name isEqual:@"menu"]) {
    @throw [NSException
        exceptionWithName:@"ErrMenuItem"
                   reason:[NSString
                              stringWithFormat:
                                  @"cannot create a MenuItem from a %@", name]
                 userInfo:nil];
  }

  item = [[MenuItem alloc] init];
  item.ID = ID;
  item.compoID = compoID;
  item.elemID = self.ID;
  item.title = label;
  item.enabled = disabled == nil ? YES : NO;

  if ([name isEqual:@"menu"]) {
    return item;
  }

  if (separator != nil) {
    item.separator = [NSMenuItem separatorItem];
    return item;
  }

  item.onClick = onClick;

  [item setupOnClick:selector];
  [item setupKeys:keys];
  return item;
}

- (id)elementByID:(NSString *)ID {
  return [self elementFromContainer:self.root ID:ID];
}

- (id)elementFromContainer:(MenuContainer *)container ID:(NSString *)ID {
  if ([container.ID isEqual:ID]) {
    return container;
  }

  for (MenuItem *child in container.children) {
    id elem = [self elementFromItem:child ID:ID];

    if (elem != nil) {
      return elem;
    }
  }

  return nil;
}

- (id)elementFromItem:(MenuItem *)item ID:(NSString *)ID {
  if ([item.ID isEqual:ID]) {
    return item;
  }

  if (item.submenu == nil) {
    return nil;
  }

  return [self elementFromContainer:(MenuContainer *)item.submenu ID:ID];
}

- (void)menuDidClose:(NSMenu *)menu {
  Driver *driver = [Driver current];

  [driver.golang
      request:[NSString stringWithFormat:@"/menu/close?id=%@", self.ID]
      payload:nil];

  [driver.elements removeObjectForKey:self.ID];
}
@end