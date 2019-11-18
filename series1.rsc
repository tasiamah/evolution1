module main

import IO;
import Set;
import List;
import Map;
import String;
import ListRelation;
import util::Math;
import util::Resources;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

list[Declaration] getASTs(loc projectLocation){
M3 model = createM3FromEclipseProject(projectLocation);
list[Declaration] asts =[];
for(m <- model.containment, m[0].scheme =="java+compilationUnit"){
asts += createAstFromFile(m[0],true);
}
return asts;
}

set[loc] getLocations(loc projectLocation){
M3 model = createM3FromEclipseProject(projectLocation);
set[loc] locations = files(model.containment);

return locations;
}

set[loc] getMethods(loc projectLocation){
M3 model = createM3FromEclipseProject(projectLocation);
set[loc] methods = methods(model);
methods += constructors(model);

return methods;
}

bool isLine(str string){
return !startsWith(string, "//") && !startsWith(string, "*") && !startsWith(string, "/*") && !startsWith(string, "@") && string != "" ;
}

int LOC(loc projectLocation){

int linesOfCode = 0;

list[loc] locations = toList(getLocations(projectLocation));

for (location <- locations){

list[str] fileLines = readFileLines(location);

for (int i <- [0..size(fileLines)]){
if (isLine(trim(fileLines[i]))){
//println("Line <i+1>: <fileLines[i]>");
linesOfCode += 1;
}
}
}
return linesOfCode;
}

list[tuple[str, loc, int]] unitSize(loc projectLocation){

list[tuple[str, loc, int]] methodLOCs = [];

list[loc] methods = toList(getMethods(projectLocation));

for (method <- methods){
str methodName = split("(", getMethodSignature(method))[0];
int linesOfCode = 0;

list[str] fileLines = readFileLines(method);

for (int i <- [0..size(fileLines)]){
if (isLine(trim(fileLines[i]))){
//println("Line <i+1>: <fileLines[i]>");
linesOfCode += 1;
}
}

methodLOCs += <methodName, method, linesOfCode>;
}
return methodLOCs;
}

list[tuple[str, int]] cyclomaticComplexity(loc location){
list[Declaration] ASTs = getASTs(location);
list[tuple[str, int]] complexity = [];

visit(ASTs){
case \method(_ , str name,_ ,_ , Statement impl) : complexity += <name, calculateCC(impl)>;
    case \constructor(str name, _, _, Statement impl) : complexity +=  <name, calculateCC(impl)>;
}

return complexity;
}

int calculateCC(Statement impl) {

    int complexity = 1;
    visit (impl) {
        case \if(_,_) : complexity += 1;
        case \if(_,_,_) : complexity += 1;
        case \do(_,_) : complexity += 1;
        case \while(_,_) : complexity += 1;
        case \case(_) : complexity += 1;
        case \for(_,_,_) : complexity += 1;
        case \for(_,_,_,_) : complexity += 1;
        case \foreach(_,_,_) : complexity += 1;
        case \catch(_,_): complexity += 1;
        case \infix(_,"&&",_) : complexity += 1;
        case \infix(_,"||",_) : complexity += 1;
        case \conditional(_,_,_): complexity += 1;
    }
    return complexity;
}

void ccMetric(loc location){

map[str, list[int]] unitSizes = toMap(toList(toSet(unitSize(location))));
list[tuple[str,int]] cyclomatic = cyclomaticComplexity(location);
int linesOfCode = LOC(location);

list[str] simple = toList(toSet([name | <name,cc> <- cyclomatic, cc >= 0 && cc <= 10]));
list[str] moreComplex = toList(toSet([name | <name,cc> <- cyclomatic, cc >= 11 && cc <= 20]));
list[str] complex = toList(toSet([name | <name,cc> <- cyclomatic, cc >= 21 && cc <= 50]));
list[str] untestable = toList(toSet([name | <name,cc> <- cyclomatic, cc > 50]));

// [0] for empty list
//int LOC_moreComplex = sum([0] + [size | name <- moreComplex, size <- unitSizes[name]]);
//int LOC_complex = sum([0] + [size | name <- complex, size <- unitSizes[name]]);
//int LOC_untestable = sum([0] + [size | name <- untestable, size <- unitSizes[name]]);

int relative = 0;

for (name <- untestable)
relative += unitSizes[name];

println(<relative>);

//list[tuple[str, int]] unstableTest = [<name, size> | name <- untestable, size <- unitSizes[name]];
//println(<unstableTest>);

//println("Simple: <simple>");
//println("More complex: <moreComplex>");
//println("Complex: <complex>");
//println("Untestable: <untestable>");

//println("Lines of code more complex: <LOC_moreComplex>");
//println("Lines of code complex: <LOC_complex>");
//println("Lines of code untestable: <LOC_untestable>");
//println("Lines of code: <linesOfCode>");
//
//real percentageMoreComplex = LOC_moreComplex / (linesOfCode * 1.0) * 100;
//real percentageComplex = LOC_complex / (linesOfCode * 1.0) * 100;
//real percentageUntestable = LOC_untestable / (linesOfCode * 1.0) * 100;
//
//println("Percentage simple: <percentageMoreComplex>%");
//println("Percentage simple: <percentageComplex>%");
//println("Percentage simple: <percentageUntestable>%");

// First int unit size, second int Cyclomatic Complexity.
//return (name : <size,cc> | <name, size> <- unitSize(|project://Test|), <nameCC, cc> <- cyclomaticComplexity(|project://Test|), name == nameCC);
}

str LOC_Metric (loc projectLocation){
int linesOfCode = LOC(projectLocation);

if (linesOfCode < 66000)
return "++";
else if(linesOfCode < 246000)
return "+";
else if(linesOfCode < 665000)
return "o";
else if(linesOfCode < 1310000)
return "-";
else
return "--";
}