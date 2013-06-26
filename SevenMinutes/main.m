//
//  main.m
//  TokyoTower
//
//  Created by Nakajima Taku on 2013/04/25.
//  Copyright (c) 2013年 Nakajima Taku. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MacRuby/MacRuby.h>

int main(int argc, char *argv[])
{
  return macruby_main("rb_main.rb", argc, argv);
}
