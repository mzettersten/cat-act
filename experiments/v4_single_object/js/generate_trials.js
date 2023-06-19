// generate trials
		
function get_training_types(
	category_kinds, 
	training_labels,
	alternate_training_labels,
	correct_category_labels) {

	//shuffle elements
	var training_labels_shuffled = jsPsych.randomization.shuffle(training_labels);
	var alternate_training_labels_shuffled = jsPsych.randomization.shuffle(alternate_training_labels);

	var training_types = {
		narrow: {
			category_kind: category_kinds["narrow"],
			category_training_level: "narrow",
			category_label_level: correct_category_labels["narrow"],
			training_label: training_labels_shuffled[0],
			alternate_training_label: alternate_training_labels_shuffled[0],
			training_image_path_info: ["sub1.jpg","sub2.jpg","sub3.jpg"]
		},
		intermediate: {
			category_kind: category_kinds["intermediate"],
			category_training_level: "intermediate",
			category_label_level: correct_category_labels["intermediate"],
			training_label: training_labels_shuffled[1],
			alternate_training_label: alternate_training_labels_shuffled[1],
			training_image_path_info: ["sub1.jpg","bas1.jpg","bas2.jpg"]
		},
		broad: {
			category_kind: category_kinds["broad"],
			category_training_level: "broad",
			category_label_level: correct_category_labels["broad"],
			training_label: training_labels_shuffled[2],
			alternate_training_label: alternate_training_labels_shuffled[2],
			training_image_path_info: ["sub1.jpg","sup1.jpg","sup2.jpg"]
		}
	};

	return(training_types)
}

function get_trial_order(category_levels) {
	var trial_order = jsPsych.randomization.shuffle(category_levels);
	return(trial_order)
}

function create_category_kinds(category_kinds,narrow_category_kind,intermediate_category_kind,broad_category_kind) {

	var category_kinds_shuffled = jsPsych.randomization.shuffle(category_kinds);

  var category_kinds_narrow = decode_category_kinds(narrow_category_kind,category_kinds_shuffled,0)
  var category_kinds_intermediate = decode_category_kinds(intermediate_category_kind,category_kinds_shuffled,1)
  var category_kinds_broad = decode_category_kinds(broad_category_kind,category_kinds_shuffled,2)

  var category_kind_assigned_dict = {
    narrow: category_kinds_narrow,
    intermediate: category_kinds_intermediate,
    broad: category_kinds_broad
  }

  return(category_kind_assigned_dict)
}

function create_correct_category_labels(narrow_category_level,intermediate_category_level,broad_category_level) {
	var narrow_category_labels = ["narrow","intermediate","broad"];
	var intermediate_category_labels = ["intermediate","broad","hypernym"];
	var broad_category_labels = ["broad","hypernym","hypernym"];

  var narrow_correct_category_label_level = decode_category_level(narrow_category_level,narrow_category_labels);
  var intermediate_correct_category_label_level = decode_category_level(intermediate_category_level,intermediate_category_labels);
  var broad_correct_category_label_level = decode_category_level(broad_category_level,broad_category_labels);

  var correct_category_labels = {
    narrow: narrow_correct_category_label_level,
    intermediate: intermediate_correct_category_label_level,
    broad: broad_correct_category_label_level
  }

  return (correct_category_labels)
}



function decode_category_kinds(category_kind_short,shuffled_category_kinds,array_index) {
  if (category_kind_short == "ani") {
    var current_category_kind = "animals";
  } else if (category_kind_short == "veh") {
    var current_category_kind = "vehicles";
  } else if (category_kind_short == "veg") {
    var current_category_kind = "vegetables";
  } else {
    var current_category_kind = shuffled_category_kinds[array_index]
  }

  return(current_category_kind)
}

function decode_category_level(category_level_short,category_level_labels) {
  if (category_level_short == "n") {
    var current_category_level = "narrow"
  } else if (category_level_short == "i") {
    var current_category_level = "intermediate"
  } else if (category_level_short == "b") {
    var current_category_level = "broad"
  } else if (category_level_short == "h") {
    var current_category_level = "hypernym"
  } else {
    var current_category_level = jsPsych.randomization.sampleWithoutReplacement(category_level_labels,1)[0];
  }

  return(current_category_level)
}

