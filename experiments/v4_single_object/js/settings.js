// SETTINGS & DEFAULT PARAMETERS

// create default image size
var grid_image_width = 100;
var grid_image_height = 100;

var image_path="stims/"

var category_kinds ={
	set1: ["animals","vegetables","vehicles"],
	set2: ["fruits","music","sea"]
};

// store names of test phase image files
var grid_image_names = {
	set1: [
"stims/ani_c3_sup3.jpg",
"stims/ani_c3_sup4.jpg",
"stims/ani_c3_sup5.jpg",
"stims/ani_c3_sup6.jpg",
"stims/ani_c3_bas3.jpg",
"stims/ani_c3_bas4.jpg",
"stims/ani_c3_sub4.jpg",
"stims/ani_c3_sub5.jpg",
"stims/veg_c1_sup3.jpg",
"stims/veg_c1_sup4.jpg",
"stims/veg_c1_sup5.jpg",
"stims/veg_c1_sup6.jpg",
"stims/veg_c1_bas3.jpg",
"stims/veg_c1_bas4.jpg",
"stims/veg_c1_sub4.jpg",
"stims/veg_c1_sub5.jpg",
"stims/veh_c2_sup3.jpg",
"stims/veh_c2_sup4.jpg",
"stims/veh_c2_sup5.jpg",
"stims/veh_c2_sup6.jpg",
"stims/veh_c2_bas3.jpg",
"stims/veh_c2_bas4.jpg",
"stims/veh_c2_sub4.jpg",
"stims/veh_c2_sub5.jpg"
		],
	set2: [
		"stims/fru_c4_sup3.jpg",
"stims/fru_c4_sup4.jpg",
"stims/fru_c4_sup5.jpg",
"stims/fru_c4_sup6.jpg",
"stims/fru_c4_bas3.jpg",
"stims/fru_c4_bas4.jpg",
"stims/fru_c4_sub4.jpg",
"stims/fru_c4_sub5.jpg",
"stims/mus_c5_sup3.jpg",
"stims/mus_c5_sup4.jpg",
"stims/mus_c5_sup5.jpg",
"stims/mus_c5_sup6.jpg",
"stims/mus_c5_bas3.jpg",
"stims/mus_c5_bas4.jpg",
"stims/mus_c5_sub4.jpg",
"stims/mus_c5_sub5.jpg",
"stims/sea_c6_sup3.jpg",
"stims/sea_c6_sup4.jpg",
"stims/sea_c6_sup5.jpg",
"stims/sea_c6_sup6.jpg",
"stims/sea_c6_bas3.jpg",
"stims/sea_c6_bas4.jpg",
"stims/sea_c6_sub4.jpg",
"stims/sea_c6_sub5.jpg"]
};

console.log(grid_image_names)

// store names of sampling phase image files
var sampling_image_names = {
	set1: [
"stims/ani_c3_sub4.jpg",
"stims/ani_c3_sup3.jpg",
"stims/ani_c3_bas3.jpg",
"stims/veg_c1_sub4.jpg",
"stims/veg_c1_sup3.jpg",
"stims/veg_c1_bas3.jpg",
"stims/veh_c2_sub4.jpg",
"stims/veh_c2_sup3.jpg",
"stims/veh_c2_bas3.jpg"],
	set2: [
"stims/fru_c4_sub4.jpg",
"stims/fru_c4_sup3.jpg",
"stims/fru_c4_bas3.jpg",
"stims/mus_c5_sub4.jpg",
"stims/mus_c5_sup3.jpg",
"stims/mus_c5_bas3.jpg",
"stims/sea_c6_sub4.jpg",
"stims/sea_c6_sup3.jpg",
"stims/sea_c6_bas3.jpg"]
};

var training_image_names = {
	set1: [
"stims/ani_c3_sub1.jpg",
"stims/ani_c3_sub2.jpg",
"stims/ani_c3_sub3.jpg",
"stims/ani_c3_bas1.jpg",
"stims/ani_c3_bas2.jpg",
"stims/ani_c3_sup1.jpg",
"stims/ani_c3_sup2.jpg",
"stims/veg_c1_sub1.jpg",
"stims/veg_c1_sub2.jpg",
"stims/veg_c1_sub3.jpg",
"stims/veg_c1_bas1.jpg",
"stims/veg_c1_bas2.jpg",
"stims/veg_c1_sup1.jpg",
"stims/veg_c1_sup2.jpg",
"stims/veh_c2_sub1.jpg",
"stims/veh_c2_sub2.jpg",
"stims/veh_c2_sub3.jpg",
"stims/veh_c2_bas1.jpg",
"stims/veh_c2_bas2.jpg",
"stims/veh_c2_sup1.jpg",
"stims/veh_c2_sup2.jpg"],
	set2: [
	"stims/fru_c4_sub1.jpg",
"stims/fru_c4_sub2.jpg",
"stims/fru_c4_sub3.jpg",
"stims/fru_c4_bas1.jpg",
"stims/fru_c4_bas2.jpg",
"stims/fru_c4_sup1.jpg",
"stims/fru_c4_sup2.jpg",
"stims/mus_c5_sub1.jpg",
"stims/mus_c5_sub2.jpg",
"stims/mus_c5_sub3.jpg",
"stims/mus_c5_bas1.jpg",
"stims/mus_c5_bas2.jpg",
"stims/mus_c5_sup1.jpg",
"stims/mus_c5_sup2.jpg",
"stims/sea_c6_sub1.jpg",
"stims/sea_c6_sub2.jpg",
"stims/sea_c6_sub3.jpg",
"stims/sea_c6_bas1.jpg",
"stims/sea_c6_bas2.jpg",
"stims/sea_c6_sup1.jpg",
"stims/sea_c6_sup2.jpg"]
};

