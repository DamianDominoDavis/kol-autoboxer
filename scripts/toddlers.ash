// make this a pref?
int recruit_price_limit = 10000;

buffer page;
string[int] price_strings;
int toddler_price;
int computed_toddler_price;
int scavenge_price;
int instructor_price;
item instructor_item;

string[string] constants = {
	"foyer":	"place.php?whichplace=town_wrong&action=townwrong_boxingdaycare",
	"enter":	"choice.php?pwd&whichchoice=1334&option=3",
	"recruit":	"choice.php?pwd&whichchoice=1336&option=1",
	"scavenge":	"choice.php?pwd&whichchoice=1336&option=2",
	"hire":		"choice.php?pwd&whichchoice=1336&option=3",
	"spar":		"choice.php?pwd&whichchoice=1336&option=4",
	"sanity_1":	"You're in the lobby of the Boxing Daycare",
	"sanity_2":	"The massive central room of the Boxing Daycare"
};

item from_plural(string multiple) {
	foreach single in $items[]
		if (single.plural == multiple)
			return single;
	return $item[none];
}

int parseint(string s) {
	return s.group_string("([0-9,]+)")[0,1].to_int();
}

boolean examine_daycare(boolean debug) {
	price_strings = page.xpath("//table//table//td[2]/text()");
	toddler_price = price_strings[0].parseint();
	computed_toddler_price = 10 ** (2 + get_property("_daycareRecruits").to_int());
	scavenge_price = price_strings[1].parseint();
	instructor_price = price_strings[2].parseint();
	instructor_item = price_strings[2].group_string("\\[[0-9,]* ?(.+?)\\]")[0,1].from_plural();
	if (debug) {
		print(`next recruit: {computed_toddler_price} meat`);
		print(`next scavenge: {scavenge_price} adventures`);
		print(`next hire:{instructor_price>0?" "+instructor_price:""} {instructor_item}`);
	}
	if (toddler_price != computed_toddler_price)
		abort("Can't determine the price of toddlers.");
}

void debug() {
	 if (!visit_url(constants["foyer"]).contains_text(constants["sanity_1"]))
		abort("Can't get to daycare.");
	page = visit_url(constants["enter"], true);
	examine_daycare(true);
}

void main() {
	 if (!visit_url(constants["foyer"]).contains_text(constants["sanity_1"]))
		abort("Can't get to daycare.");
	page = visit_url(constants["enter"], true);
	while (page.contains_text(constants["sanity_2"])) {
		//0: Redetermine costs
		examine_daycare(false);
		
		// 1: Free scavenge
		if (scavenge_price == 0) {
			visit_url(constants["scavenge"], true);
		}

		// 2: Hire instructor whenever available
		else if (instructor_item != $item[none]) {
			print("Hiring an instructor for "+instructor_price+" "+instructor_item);
			retrieve_item(instructor_price, instructor_item);
			if (item_amount(instructor_item) < instructor_price)
				abort("Couldn't acquire "+instructor_price+" "+instructor_item);
			visit_url(constants["hire"], true);
		}

		// 3: Recruit toddlers once if under/at recruit_price_limit
		else if (recruit_price_limit >= computed_toddler_price) {
			if (computed_toddler_price > my_meat())
				abort("Can't afford to recruit toddlers for "+computed_toddler_price+" meat.");
			visit_url(constants["recruit"], true);
		}

		// 4: First spar of the day
		else if (get_property("_daycareFights") != 'true') {
			visit_url(constants["spar"], true);
		}

		// 5: Quit
		else {
			print("Finished boxing toddlers.");
			return;
		}
		page = visit_url(constants["enter"], true);
	}
	abort("Had a bad day at daycare...");
}
