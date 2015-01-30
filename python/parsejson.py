#!/usr/bin/python
import json
import datetime
import os
import dbapi
filename="3.json"
###sap hana server information
serverAddress='10.128.84.28'
serverPort=30015
userName='SYSTEM'
passWord='manager'
#connect to hana database
conn=dbapi.connect(serverAddress,serverPort,userName,passWord)
#query for questions
query_q="UPSERT STOF.QUESTIONS(QID,CREATE_DATE,TITLE,BODY,SCORE,ANSWER_COUNT,DOWN_VOTE_COUNT,UP_VOTE_COUNT,IS_ANSWERED,ACCEPTED_ANSWER_ID,COMMENT_COUNT,VIEW_COUNT,USERID) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?) WITH PRIMARY KEY"
query_tag="UPSERT STOF.TAGS(POSTID,IDTYPE,TAG) VALUES(?,?,?) WITH PRIMARY KEY"
query_owner="UPSERT STOF.USERS(USERID,USER_TYPE,REPUTATION,ACCEPT_RATE,PROFILE_IMAGE,DISPLAY_NAME,LINK) values(?,?,?,?,?,?,?) with primary key"
query_comment="UPSERT STOF.COMMENTS(COMMENT_ID,OWNERID,CREATION_DATE,POST_ID,BODY,SCORE,REPLY_TO_USER) values(?,?,?,?,?,?,?) with primary key"
query_answer="UPSERT STOF.ANSWERS(ANSWER_ID,QUESTION_ID,TITLE,BODY,CREATION_DATE,SCORE,IS_ACCEPTED,DOWN_VOTE_COUNT,UP_VOTE_COUNT,COMMENT_COUNT,USERID) VALUES(?,?,?,?,?,?,?,?,?,?,?) with PRIMARY KEY"
#######################usert a user########################
def upsertuser(user):
    if user.has_key("reputation"):
	reputation=user["reputation"]
    else:
	reputation=0
    if user.has_key("accept_rate"):
	accept_rate=user["accept_rate"]
    else:
	accept_rate=0

    try:
	cursor.execute(query_owner,(user["user_id"],user["user_type"],reputation,accept_rate,user["profile_image"],user["display_name"],user["link"]))
    except Exception,ex:
	print ex
	   
###################upsert a comment#########################
def upsertcomment(comment):
    upsertuser(comment["owner"])
    if comment.has_key("reply_to_user"):
	reply_user=comment["reply_to_user"]
	upsertuser(reply_user)
	replyuserid=comment["reply_to_user"]["user_id"]
    else:
	replyuserid=0
    creation_date=comment["creation_date"]
    creation_date=datetime.datetime.fromtimestamp(int(creation_date)).strftime('%Y-%m-%d %H:%M:%S')
    try:
	cursor.execute(query_comment,(comment["comment_id"],comment["owner"]["user_id"],creation_date,comment["post_id"],comment["body"],comment["score"],replyuserid))
    except Exception,ex:
	print ex

####################upsert an answer########################
def upsertanswer(answer):
    owner=answer["owner"]
    upsertuser(owner)
    userid=owner["user_id"]
    creation_date=answer["creation_date"]
    creation_date=datetime.datetime.fromtimestamp(int(creation_date)).strftime('%Y-%m-%d %H:%M:%S')
    if len(answer["tags"])>0:
	for j in range(0,len(answer["tags"])):
	    try:
		 cursor.execute(query_tag,(answer["answer_id"],"answers",answer["tags"][j]))
	    except Exception,ex:
		print ex
    if answer["comment_count"]>0:
	for j in range(0,answer["comment_count"]):
	    upsertcomment(answer["comments"][j])
    try:
	cursor.execute(query_answer,(answer["answer_id"],answer["question_id"],answer["title"],answer["body"],creation_date,answer["score"],int(answer["is_accepted"]),answer["down_vote_count"],answer["up_vote_count"],answer["comment_count"],userid))
    except Exception,ex:
	print ex
#########Entry point#############################################
try:
    fp=open(filename)
    jsonobj=json.load(fp)
    fp.close()
except Exception,e:
    print("open file or parse json failed!Quit!")
    os.exit()
cursor=conn.cursor()

items=jsonobj["items"]

for i in range(0,len(items)):
    item=jsonobj["items"][i]
    #get the fields
    qid=item["question_id"]
    title=item["title"]
    body=item["body"]
    creation_date=item["creation_date"]
    creation_date=datetime.datetime.fromtimestamp(int(creation_date)).strftime('%Y-%m-%d %H:%M:%S')
    score=item["score"]
    answer_count=item["answer_count"]
    down_vote_count=item["down_vote_count"]
    up_vote_count=item["up_vote_count"]
    is_answered=int(item["is_answered"])
    accepted_answer_id=0
    if is_answered and item.has_key("accepted_answer_id"):
	accepted_answer_id=item["accepted_answer_id"]
    comment_count=item["comment_count"]
    view_count=item["view_count"]
    tags=item["tags"]
    for j in range(0,len(tags)):
	tag=tags[j];
	try:
	    cursor.execute(query_tag,(qid,"questions",tag))
	except Exception,ex:
	    print ex

    owner=item["owner"]

    upsertuser(owner)

    user_id=owner["user_id"]

    try:
	cursor.execute(query_q,(qid,creation_date,title,body,score,answer_count,down_vote_count,up_vote_count,is_answered,accepted_answer_id,comment_count,view_count,user_id))
    except Exception,ex:
	print ex
    
    if comment_count>0:
	for m in range(0,comment_count):
	    comm=item["comments"][m]
	    upsertcomment(comm)
    
    if answer_count>0:
	for n in range(0,answer_count):
	    answer=item["answers"][n]
	    upsertanswer(answer)

cursor.close()
conn.close()
