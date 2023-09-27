function create_demographics() {
    var demographic_block=[];

//demographics
var demo_1 = {
    type: 'survey-text',
    preamble: "Next, we have just a few demographic questions.",
    timeline: [
    {questions: [{prompt: "Please enter your age (in number of years; e.g., 30).",name: "age", required: true}]},
    {questions: [{prompt: "What is your gender?",name: "gender", required: true}]},
    {questions: [{prompt: "What country do you currently live in? (e.g., United States)", name: "country", required: true}]},
    {questions: [{prompt: "What is your first/ primary language(s)?", name: "language", required: true},{prompt: "Please list any other languages you are fluent in.", name: "other_languages"}]},

    ]
  }
  demographic_block.push(demo_1);

  var demo_2 = {
  type: 'survey-multi-select',
  preamble: "Next, we have just a few demographic questions.",
  questions: [
    {
      prompt: "What is your race or ethnicity? Please check one or more boxes.", 
      options: ["White","Black or African American", "Hispanic or Latino", "American Indian or Alaska Native", "Asian", "Native Hawaiian or Other Pacific Islander","Not listed","Prefer not to answer"], 
      horizontal: false,
      required: true,
      name: 'race'
    }
    ]
  }
  demographic_block.push(demo_2);

  var demo_3 = {
  type: 'survey-multi-choice',

  questions: [
    {
      prompt: "What is your current level of education?", 
      options: ["Some high school", "High school", "Some college/ university", "Bachelor's degree", "Master's degree","Doctoral degree","Other professional degree","Not applicable/ unknown","Other","Prefer not to answer"], 
      horizontal: false,
      required: true,
      name: 'education'
    }
    ]
    } 
  demographic_block.push(demo_3);

  return(demographic_block)

}

function create_debrief_questions() {

  var debrief_block = [];


//game questions
var debrief_questions = {
    type: 'survey-text',
    questions: [
      {prompt: "Did you encounter any issues during the task?", name: "issues", rows: 3,columns: 60},
    {prompt: "Any additional comments?", name: "comments", rows: 3,columns: 60}
    ],

  }

  debrief_block.push(debrief_questions);

  return(debrief_block)

}

//general function for grabbing parameter from a URL
function getParamFromURL( name ) {
  name = name.replace(/[\[]/,"\\[").replace(/[\]]/,"\\]");
  var regexS = "[\?&]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var results = regex.exec( window.location.href );
  if( results == null )
    return "";
  else
    return results[1];
}

//create random code for final message
//start code creation script
function randLetter() {
  var a_z = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  var int =  Math.floor((Math.random() * a_z.length));
  var rand_letter = a_z[int];
  return rand_letter;
};

function createCode(secretCode,codelength_begin=7,codelength_end=10) {
  var code = "";
  for (var i = 0; i < codelength_begin; i++){
    code = code.concat(randLetter());
  };

  code = code.concat(secretCode);

  for (var i = 0; i < codelength_end; i++){
    code = code.concat(randLetter());
  }

  return code
}