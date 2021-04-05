%option noyywrap

%x CHAR_STATE
%x STRING_STATE
%x SINGLE_COMMENT_STATE
%x MULTI_COMMENT_STATE

%{
#include<iostream>
#include<algorithm>
#include<string>
#include"SymbolTable.cpp"


int line_count=1;
int error_count = 0;

FILE *logout;
FILE *tokenout;

SymbolTable *symboltable;

%}

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE (\n)|(\r\n)

KEYWORDS "if"|"else"|"for"|"while"|"do"|"break"|"int"|"char"|"float"|"double"|"void"|"return"|"switch"|"case"|"default"|"continue"


INTEGER {DIGIT}*
FLOAT {DIGIT}*(\.{DIGIT}*)?(E[+-]?{DIGIT}*)?

ADDOP "+"|"-"
MULOP (\*)|(\/)|(%)
INCOP "++"|"--"
RELOP (<)|(<=)|(>)|(>=)|(==)|(!=)
ASSIGNOP "="
LOGICOP "&&"|"||"
NOT "!"
LPAREN "("
RPAREN ")"
LCURL "{"
RCURL "}"
LTHIRD "["
RTHIRD "]"
COMMA ","
SEMICOLON ";"


ID ({LETTER}|_)+({LETTER}|{DIGIT}|_)*

INVALID_PREFIX_ID {DIGIT}+({LETTER}|_)({LETTER}|{DIGIT}|_)*

TOO_MANY_DECIMAL {DIGIT}*(\.{DIGIT}*)(\.{DIGIT}*)+(.)*
ILL_NUMBER_1 {DIGIT}*(\.{DIGIT}*)?(E[+-]?{DIGIT}*(\.))(.)*
ILL_NUMBER_2 {DIGIT}*(\.)(E[+-]?{DIGIT}*)?


%%

{NEWLINE} {line_count++;}




\" {
		yymore();
		BEGIN STRING_STATE;
	}
	
<STRING_STATE><<EOF>> {
		error_count++;
		fprintf(logout,"Error at line no %d: Unterminated String %s\n\n",line_count,yytext);
		
		BEGIN INITIAL;
	}
	
<STRING_STATE>\\{NEWLINE} {
		line_count++;
		yymore();
	}
	
<STRING_STATE>[^"\n] {
		yymore();
	}
	
	
<STRING_STATE>(\") {


		char temp_char[strlen(yytext)];
		strcpy(temp_char, yytext);

		string temp(temp_char), actual = "";
		
		for(int i=0; i<temp.length(); i++)
		{
			if(temp[i] == '\\')
			{
				if(i+1 >= temp.length())
				{
					actual += temp[i];
					continue;
				}
				i++;
				if(temp[i] == '\r' && i+1 < temp.length() && temp[i+1] == '\n')
				{
					i++;
					continue;
				}
					
				if(temp[i] == '\n')
					continue;
				else if(temp[i] == 'n')
					actual += '\n';
				else if(temp[i] == 't')
					actual += '\t';
				else if(temp[i] == '\\')
					actual += '\\';
				else if(temp[i] == '\'')
					actual += '\'';
				else if(temp[i] == 'a')
					actual += '\a';
				else if(temp[i] == 'f')
					actual += '\f';
				else if(temp[i] == 'r')
					actual += '\r';
				else if(temp[i] == 'b')
					actual += '\b';
				else if(temp[i] == 'v')
					actual += '\v';
				else if(temp[i] == '0')
					actual += '\0';
				
				else if(temp[i] == '\"')
					actual += '\"';
				else 
				{
					i--;
					actual += temp[i];
				}
				
			}
			else
				actual += temp[i];
			
		}
		
		fprintf(tokenout,"<STRING,%s> ", actual.c_str());
		fprintf(logout,"Line no %d: Token <STRING> Lexeme %s found --> <STRING, %s> \n\n",line_count,yytext, actual.c_str());
		BEGIN INITIAL;
	} 
	
<STRING_STATE>\n {
		line_count++;
		error_count++;
		//fprintf(logout, "ami jhamela kortesi\n");
		fprintf(logout,"Error at line no %d: Unterminated String %s\n\n",line_count,yytext);
		
		BEGIN INITIAL;
		
	}
	
	
	

\' {
		yymore();
		BEGIN CHAR_STATE;
	}

<CHAR_STATE><<EOF>> {
		error_count++;
		fprintf(logout,"Error at line no %d: Unterminated character %s\n\n",line_count,yytext);
		BEGIN INITIAL;
	}



<CHAR_STATE>(\\)(\')/(\') {
		yymore();
	}

<CHAR_STATE>\' {
		
		char temp[strlen(yytext)];
		strcpy(temp, yytext);

		char ch;

		string literal(temp);
		
		if(literal.length() == 2)
		{	
			error_count++;
			fprintf(logout,"Error at line no %d: Empty character constant error %s\n\n",line_count,yytext);
			BEGIN INITIAL;
			break;

		}
		
		
		if(literal[1] == '\\')
		{
			if(literal.length()<4)
			{
				error_count++;
				fprintf(logout,"Error at line no %d: Unterminated character %s\n\n", line_count, yytext);
				BEGIN INITIAL;
				break;
			}

			if(literal.length() >4)
			{
				error_count++;
				fprintf(logout,"Error at line no %d: Multi character constant error %s\n\n", line_count, yytext);
				BEGIN INITIAL;
				break;
			}
			
			bool is_literal = true;

			if(literal[2] == 'n')
				ch = '\n';
			else if(literal[2] == 't')
				ch = '\t';
			else if(literal[2] == '\\')
				ch = '\\';
			else if(literal[2] == '\'')
				ch = '\'';
			else if(literal[2] == 'a')
				ch = '\a';
			else if(literal[2] == 'f')
				ch = '\f';
			else if(literal[2] == 'r')
				ch = '\r';
			else if(literal[2] == 'b')
				ch = '\b';
			else if(literal[2] == 'v')
				ch = '\v';
			else if(literal[2] == '0')
				ch = '\0';
			else
				is_literal = false;

			if(is_literal)
			{
	
				char temp2[strlen(yytext)];
				strcpy(temp2, yytext);
						
				string push(temp2);

				fprintf(tokenout,"<CONST_CHAR,%c> ", ch);
				fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CHAR_CONST, %c>\n\n",line_count,yytext, ch);
			
				bool inserted = symboltable->Insert(push, "CONST_CHAR");

			
				if(inserted)
				{
					symboltable->print_all(logout);
				}
				else
				{
					fprintf(logout,"%s already exists in current ScopeTable\n\n", yytext);
				}
				
				
				BEGIN INITIAL;
			}
			else 
			{	
				fprintf(logout,"Error at line no %d: Unknown character %s found\n\n",line_count,yytext);
			}
			
		
		}
		else if(literal[2] == '\'')
		{
			char temp2[strlen(yytext)];
			strcpy(temp2, yytext);

			ch = literal[1];
						
			string push(temp2);

			

			fprintf(tokenout,"<CONST_CHAR,%c> ", ch);
			fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CHAR_CONST, %c>\n\n",line_count,yytext, ch);
			
			bool inserted = symboltable->Insert(push, "CONST_CHAR");
			
			if(inserted)
			{
				symboltable->print_all(logout);
			}
			else
			{
				fprintf(logout,"%s already exists in current ScopeTable\n\n", yytext);
			}
			
			BEGIN INITIAL;


		}
		else
		{
			error_count++;
			fprintf(logout,"Error at line no %d: Multi character constant error %s\n\n", line_count, yytext);
			BEGIN INITIAL;
		}

		
				
	}
	
	
<CHAR_STATE>[^\n] {
		yymore();
	}
	
<CHAR_STATE>\n {
		line_count++;
		error_count++;
		
		fprintf(logout,"Error at line no %d: Unterminated character %s\n\n", line_count, yytext);
		BEGIN INITIAL;
	}


\/\/ {
		yymore();
		BEGIN SINGLE_COMMENT_STATE;
	
	}

<SINGLE_COMMENT_STATE><<EOF>> {
		BEGIN INITIAL;
			
	}

<SINGLE_COMMENT_STATE>\\$ {
		yymore();
		line_count++;
		}

<SINGLE_COMMENT_STATE>[^{NEWLINE}] {
		yymore();	
	}

<SINGLE_COMMENT_STATE>{NEWLINE} {
		char temp[strlen(yytext)];
		strcpy(temp, yytext);

		string comment(temp);
		
		//if(comment[comment.length()-1] == '\n')
		comment.pop_back();
		comment.pop_back();
		
		
		line_count++;
		fprintf(logout,"Line no %d: Token <COMMENT> Lexeme %s found\n\n",line_count,comment.c_str());

		BEGIN INITIAL;
	}




\/\* {
	yymore();
	BEGIN MULTI_COMMENT_STATE;
	}

<MULTI_COMMENT_STATE><<EOF>> {
		error_count++;

		fprintf(logout,"Error at line no %d: Unterminated Comment %s\n\n",line_count,yytext);

		BEGIN INITIAL;
		
	}

<MULTI_COMMENT_STATE>{NEWLINE} {
		yymore();
		line_count++;
	}

<MULTI_COMMENT_STATE>[^\*\/] {
		yymore();		
	}
	
<MULTI_COMMENT_STATE>. {
		yymore();
	}


<MULTI_COMMENT_STATE>(\*)(\/) {
		fprintf(logout,"Line no %d: Token <COMMENT> Lexeme %s found\n\n",line_count,yytext);
		BEGIN INITIAL;		
	}





{KEYWORDS} {
		char temp[strlen(yytext)];
		strcpy(temp, yytext);

		string upper(temp);


		for(int i=0; i<upper.length(); i++)
		{
			upper[i] = upper[i] - 32;
		
		}

		fprintf(tokenout,"<%s> ", upper.c_str());
		fprintf(logout,"Line no %d: Token <%s> Lexeme %s found\n\n",line_count, upper.c_str(),yytext);
	}


{INTEGER} {
		char temp[strlen(yytext)];
		strcpy(temp, yytext);

		string num(temp);		

		
		fprintf(tokenout,"<CONST_INT,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <CONST_INT> Lexeme %s found\n\n",line_count,yytext);
		
		bool inserted = symboltable->Insert(num, "CONST_INT");

		
		if(inserted)
		{
			symboltable->print_all(logout);
		}
		else
		{
			fprintf(logout,"%s already exists in current ScopeTable\n\n", yytext);
		}

}

{FLOAT} {
		char temp[strlen(yytext)];
		strcpy(temp, yytext);

		string num(temp);		

		
		fprintf(tokenout,"<CONST_FLOAT,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <CONST_FLOAT> Lexeme %s found\n\n",line_count,yytext);
		
		bool inserted = symboltable->Insert(num, "CONST_FLOAT");

		
		if(inserted)
		{
			symboltable->print_all(logout);
		}
		else
		{
			fprintf(logout,"%s already exists in current ScopeTable\n\n", yytext);
		}
		
	}



{TOO_MANY_DECIMAL} {
		error_count++;
		fprintf(logout,"Error at line no %d: Too many decimal points %s\n\n",line_count,yytext);
		
	}



{ILL_NUMBER_1}|{ILL_NUMBER_2} {
		error_count++;
		fprintf(logout,"Error at line no %d: Ill formed number %s\n\n",line_count,yytext);
		
	}







{ADDOP} {
		fprintf(tokenout,"<ADDOP,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <ADDOP> Lexeme %s found\n\n",line_count,yytext);
		
	}

{MULOP} {
		fprintf(tokenout,"<MULOP,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <MULOP> Lexeme %s found\n\n",line_count,yytext);
		
	}

{INCOP} {
		fprintf(tokenout,"<INCOP,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <INCOP> Lexeme %s found\n\n",line_count,yytext);
		
	}


{RELOP} {
		fprintf(tokenout,"<RELOP,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <RELOP> Lexeme %s found\n\n",line_count,yytext);
		
	}



{ASSIGNOP} {
		fprintf(tokenout,"<ASSIGNOP,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <ASSIGNOP> Lexeme %s found\n\n",line_count,yytext);
		
	}



{LOGICOP} {
		fprintf(tokenout,"<LOGICOP,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <LOGICOP> Lexeme %s found\n\n",line_count,yytext);
		
	}



{NOT} {
		fprintf(tokenout,"<NOT,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <NOT> Lexeme %s found\n\n",line_count,yytext);
		
	}



{LPAREN} {
		fprintf(tokenout,"<LPAREN,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <LPAREN> Lexeme %s found\n\n",line_count,yytext);
		
	}



{RPAREN} {
		fprintf(tokenout,"<RPAREN,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <RPAREN> Lexeme %s found\n\n",line_count,yytext);
		
	}


{LCURL} {
		symboltable->enterScope();
		fprintf(tokenout,"<LCURL,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <LCURL> Lexeme %s found\n\n",line_count,yytext);
		
	}


{RCURL} {
		symboltable->exitScope();
		fprintf(tokenout,"<RCURL,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <RCURL> Lexeme %s found\n\n",line_count,yytext);
		
	}


{LTHIRD} {
		fprintf(tokenout,"<LTHIRD,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <LTHIRD> Lexeme %s found\n\n",line_count,yytext);
		
	}


{RTHIRD} {
		fprintf(tokenout,"<RTHIRD,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <RTHIRD> Lexeme %s found\n\n",line_count,yytext);
		
	}



{COMMA} {
		fprintf(tokenout,"<COMMA,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <COMMA> Lexeme %s found\n\n",line_count,yytext);
		
	}



{SEMICOLON} {
		fprintf(tokenout,"<SEMICOLON,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <SEMICOLON> Lexeme %s found\n\n",line_count,yytext);
		
	}

{ID} {

		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		string id(temp);		
		
		fprintf(tokenout,"<ID,%s> ",yytext);
		fprintf(logout,"Line no %d: Token <ID> Lexeme %s found\n\n",line_count,yytext);
		
		bool inserted = symboltable->Insert(id, "ID");
		
		if(inserted)
		{
			symboltable->print_all(logout);
		}
		else
		{
			fprintf(logout,"%s already exists in current ScopeTable\n\n", yytext);
		}
	}


{INVALID_PREFIX_ID} {
		error_count++;
		fprintf(logout,"Error at line no %d: Invalid prefix on ID or invalid suffix on Number %s\n\n",line_count,yytext);
	}
	
	
{WHITESPACE} {}

. {
		error_count;
		fprintf(logout,"Error at line no %d: Unrecognized character %s\n\n",line_count,yytext);
	}
%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout= fopen("1705018_log.txt","w");
	tokenout= fopen("1705018_token.txt","w");

	symboltable = new SymbolTable(7);

	yyin= fin;
	yylex();
	
	symboltable->print_all(logout);

	fprintf(logout,"Total lines: %d\n",line_count);
	fprintf(logout,"Total errors: %d",error_count);

	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;
}
