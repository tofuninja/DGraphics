module graphics.gui.themes;

import graphics.gui.div;
import graphics.color;
import std.algorithm;

enum Themes : Style
{
	Gray = {
		Style s;
		s.background 	= RGB(90,90,90);
		s.foreground 	= RGB(130, 130, 130);
		s.text 			= RGB(255,255,255);
		s.lower 		= RGB(110,110,110);
		s.button		= RGB(70,70,70);
		s.text_hint		= RGB(150,150,150);
		s.split			= RGB(70,70,70);
		s.scroll		= RGB(150,150,150);
		return s;
	}(),
	Contrast = {
		Style s; // The default style is already a contrast theme
		return s;
	}(),
	Default = {
		Style s;
		return s;
	}()
}