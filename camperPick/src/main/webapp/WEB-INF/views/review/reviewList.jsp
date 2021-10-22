<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/bootstrap.min.css">
<script type="text/javascript" src="${pageContext.request.contextPath}/resources/js/jquery-3.6.0.min.js"></script>      

<script type="text/javascript">
	$(function() {
		
		
		var currentPage;
		var count;
		var rowCount;
		//댓글 목록
		function selectData(pageNum,camping_num){
			currentPage = pageNum;
			
			if(pageNum == 1){
				//처음 호출시는 해당 ID의 div의 내부 내용물을 제거
				$('#output').empty();
			}
			
			//로딩 이미지 노출
			$('#loading').show();
			
			$.ajax({
				type:'post',
				data:{pageNum:pageNum,camping_num:camping_num},
				url:'../review/reviewList.do',
				dataType:'json',
				cache:false,
				timeout:30000,
				success:function(param){
					//로딩 이미지 감추기
					$('#loading').hide();
					count = param.count;
					rowCount = param.rowCount;
					var user_auth = ${user_auth};
					$(param.list).each(function(index,item){
						var output = '<div class="item">';
						output += '<h4>' + item.title + '</h4>';
						output += '<div class="sub-item">';
						output +='   <p>' + item.content.replace(/</gi,'&lt;').replace(/>/gi,'&gt;') + '</p>';
						if(item.filename){
							output +='   <div><img src="${pageContext.request.contextPath}/review/photoView.do?review_num='+item.review_num+'" style="max-width:100px;"></div>';
						}
						output += item.reg_date; 
						if($('#mem_num').val() && user_auth == 4){
							output += ' <input type="button" data-num="'+item.review_num+'" data-mem="'+item.res_num+'" value="답글 작성" class="write-btn">';
						}
						output +='<input type="button" data-num="'+item.review_num+'" data-mem="'+item.res_num+'" value="답글 보기" class="view-btn">';
						if($('#mem_num').val()==item.mem_num){
							//로그인한 회원 번호가 댓글 작성자 회원 번호와 같으면
							output += ' <input type="button" data-num="'+item.review_num+'" data-mem="'+item.mem_num+'" value="수정" class="modify-btn">';
							output += ' <input type="button" data-num="'+item.review_num+'" data-mem="'+item.mem_num+'" value="삭제" class="delete-btn">';
						
						 }
						output += '  <hr size="1" noshade>';
						output += '</div>';
						output += '</div>';
						
						//문서 객체에 추가
						$('#output').append(output);
						
					});//end of each
					
					//paging button 처리
					if(currentPage>=Math.ceil(count/rowCount)){
						//다음 페이지가 없음
						$('.paging-button').hide();
					}else{
						//다음 페이지가 존재
						$('.paging-button').show();
					}
					
				},
				error:function(){
					alert('네트워크 오류 발생');
				}
			});
			
		}
		//다음 댓글 보기 버튼 클릭시 데이터 추가
		$('.paging-button input').click(function(){
			var pageNum = currentPage + 1;
			selectData(pageNum,$('#camping_num').val());
		});
		//댓글 등록
		$('#re_form').submit(function(event){
			if($('#re_content').val().trim()==''){
				alert('내용을 입력하세요!');
				$('#re_content').val('').focus();
				return false;
			}
			var data = $(this).serialize();
			//등록
			//파일 전송
			var form_data = new FormData($(this)[0]);
			$.ajax({
				data:form_data,
				type:'post',
				url:'../review/writeReview.do',
				dataType:'json',
				cache:false,
				contentType:false,
				enctype:'multipart/form-data',
				processData:false,
				success:function(param){
					if(param.result == 'logout'){
						alert('로그인해야 작성할 수 있습니다.');
					}else if(param.result == 'success'){
						//폼초기화
						initForm();
						//댓글 작성이 성공하면 새로 삽입한 글을 포함해서 첫번째 페이지의
						//게시글들을 다시 호출
						selectData(1,$('#camping_num').val());
					}else{
						alert('댓글 등록시 오류 발생!');
					}
				},
				error:function(){
					alert('네트워크 오류 발생');
				}
			});
			//기본 이벤트 제거
			event.preventDefault();
		});
		//댓글 작성 폼 초기화
		function initForm(){
			$('textarea').val('');
			$('#re_first .letter-count').text('1000/1000');
		}
		//textarea에 내용 입력시 글자수 체크
		$(document).on('keyup','textarea',function(){
			//남은 글자수를 구함
			var inputLength = $(this).val().length;
			
			if(inputLength>1000){//1000자를 넘어선 경우
				$(this).val($(this).val().substring(0,1000));
			}else{//1000자 이하인 경우
				var remain = 1000 - inputLength;
				remain += '/1000';
				if($(this).attr('id') == 're_content'){
					//등록폼 글자수
					$('#re_first .letter-count').text(remain);
				}else{
					//수정폼 글자수
					$('#mre_first .letter-count').text(remain);
				}
			}
		});
		//댓글 수정 버튼 클릭시 수정폼 노출
		$(document).on('click','.modify-btn',function(){
			//댓글 글번호
			var review_num = $(this).attr('data-num');
			//작성자 회원 번호
			var mem_num = $(this).attr('data-mem');
			//댓글 내용
			var content = $(this).parent().find('p').html().replace(/<br>/gi,'\n');
			
			//댓글 수정폼 UI
			var modifyUI = '<form id="mre_form">';
			   modifyUI += '  <input type="hidden" name="review_num" id="mre_num" value="'+review_num+'">';
			   modifyUI += '  <input type="hidden" name="mem_num" id="mmem_num" value="'+mem_num+'">';
			   modifyUI += '  <textarea rows="3" cols="50" name="content" id="mre_content" class="rep-content">'+content+'</textarea>';
			   modifyUI += '  <div id="mre_first"><span class="letter-count">1000/1000</span></div>';	
			   modifyUI += '  <div id="mre_second" class="align-right">';
			   modifyUI += '     <input type="submit" value="수정">';
			   modifyUI += '     <input type="button" value="취소" class="re-reset">';
			   modifyUI += '  </div>';
			   modifyUI += '  <hr size="1" noshade width="90%">';
			   modifyUI += '</form>';
			   
			//이전에 이미 수정하는 댓글이 있을 경우 수정버튼을 클릭하면
			//숨김 sub-item을 환원시키고 수정폼을 초기화함
			initModifyForm();
			
			//지금 클릭해서 수정하고자 하는 데이터는 감추기
			//수정버튼을 감싸고 있는 div
			$(this).parent().hide();
			
			//수정폼을 수정하고자하는 데이터가 있는 div에 노출
			$(this).parents('.item').append(modifyUI);
			
			//입력한 글자수 셋팅
			var inputLength = $('#mre_content').val().length;
			var remain = 1000 - inputLength;
			remain += '/1000';
			
			//문서 객체에 반영
			$('#mre_first .letter-count').text(remain);		
		});
		//수정폼에서 취소 버튼 클릭시 수정폼 초기화
		$(document).on('click','.re-reset',function(){
			initModifyForm();
		});
		//댓글 수정 폼 초기화
		function initModifyForm(){
			$('.sub-item').show();
			$('#mre_form').remove();
		}
		//댓글 수정
		$(document).on('submit','#mre_form',function(event){
			if($('#mre_content').val().trim()==''){
				alert('내용을 입력하세요');
				$('#mre_content').val('').focus();
				return false;
			}
			
			//폼에 입력한 데이터 반환
			var data=$(this).serialize();
			
			//수정
			$.ajax({
				url:'../review/updateReview.do',
				type:'post',
				data:data,
				dataType:'json',
				cache:false,
				timeout:30000,
				success:function(param){
					if(param.result =='logout'){
						alert('로그인해야 수정할 수 있습니다.')
					}else if(param.result == 'success'){
						$('#mre_form').parent().find('p').html($('#mre_content').val().replace(/</g,'&lt;').replace(/>/g,'&gt;'));
						//수정폼 초기화
						initModifyForm();
					}else if(param.result == 'wrongAccess'){
						alert('타인의 글을 수정할 수 없습니다.');
					}else{
						alert('댓글 수정시 오류 발생');
					}
				},
				error:function(){
					alert('네트워크 오류발생');
				}
			});
			
			//기본 이벤트 제거
			event.preventDefault();
			
		});
		
		//댓글 삭제
		$(document).on('click','.delete-btn',function(){
			//댓글 번호
			var review_num = $(this).attr('data-num');
			//작성자 회원 번호
			var mem_num = $(this).attr('data-mem');
			
			$.ajax({
				type:'post',
				url:'../review/deleteReview.do',
				data:{review_num:review_num,mem_num:mem_num},
				dataType:'json',
				cache:false,
				timeout:30000,
				success:function(param){
					if(param.result == 'logout'){
						alert('로그인해야 삭제할 수 있습니다.');
					}else if(param.result == 'success'){
						alert('삭제가 완료되었습니다');
						selectData(1,$('#camping_num').val());
					}else if(param.result == 'wrongAccess'){
						alert('타인의 글을 삭제할 수 없습니다.');
					}else{
						alert('댓글 삭제시 오류 발생');
					}
				},
				error:function(){
					alert('네트워크 오류 발생');
				}
			});
			
		});
		//초기 데이터(목록) 호출
		selectData(1,$('#camping_num').val());
		
		
		// 사진 수정
		$('#photo_btn').click(function(){
			$('#photo_choice').show();
			$(this).hide();
		});
		
		//파일 미리 보기
		var photo_path;
		var review_photo;
		$('#upload').change(function(){
			var upload = document.getElementById('upload');
			review_photo = upload.files[0];
			if(review_photo){
				var reader = new FileReader();
				
				reader.readAsDataURL(review_photo);
				
				reader.onload = function(){
					photo_path = $('.review-photo').attr('src');
					$('.review-photo').attr('src',reader.result);
				};
			}
		});
		/* 대댓글==================================================================== */
		
		//대댓글 등록---------------
		$(document).on('submit','#wre_form',function(event){
			if($('#mre_content').val().trim()==''){
				alert('내용을 입력하세요!');
				$('#mre_content').val('').focus();
				return false;
			}
			var data = $(this).serialize();
			//등록
			//파일 전송
			var form_data = new FormData($(this)[0]);
			$.ajax({
				data:form_data,
				type:'post',
				url:'../review/writeReReview.do',
				dataType:'json',
				cache:false,
				contentType:false,
				enctype:'multipart/form-data',
				processData:false,
				success:function(param){
					if(param.result == 'logout'){
						alert('로그인해야 작성할 수 있습니다.');
					}else if(param.result == 'success'){
						//폼초기화
						initWriteForm();
						//댓글 작성이 성공하면 새로 삽입한 글을 포함해서 첫번째 페이지의
						//게시글들을 다시 호출
						selectData(1,$('#camping_num').val());
					}else{
						alert('댓글 등록시 오류 발생!');
					}
				},
				error:function(){
					alert('네트워크 오류 발생');
				}
			});
			//기본 이벤트 제거
			event.preventDefault();
		});
		//댓글 작성 폼 초기화
		function initModifyForm(){
			$('textarea').val('');
			$('#mre_first .letter-count').text('1000/1000');
		}
		//textarea에 내용 입력시 글자수 체크
		$(document).on('keyup','textarea',function(){
			//남은 글자수를 구함
			var inputLength = $(this).val().length;
			
			if(inputLength>1000){//1000자를 넘어선 경우
				$(this).val($(this).val().substring(0,1000));
			}else{//1000자 이하인 경우
				var remain = 1000 - inputLength;
				remain += '/1000';
				if($(this).attr('id') == 're_content'){
					//등록폼 글자수
					$('#mre_first .letter-count').text(remain);
				}else{
					//수정폼 글자수
					$('#mmre_first .letter-count').text(remain);
				}
			}
		});	
		
		
		
		//대댓글 작성 버튼 클릭시 대댓글 작성폼 노출------------
		$(document).on('click','.write-btn',function(){
			//댓글 글번호
			var review_num = $(this).attr('data-num');
			//예약 번호
			var res_num = $(this).attr('data-mem');
			//대댓글 작성자 회원 번호
			var mem_num = ${user_num};
			
			//대댓글 작성폼 UI
			var modifyUI = '<form id="wre_form">';
			   modifyUI += '  <input type="hidden" name="review_num" id="mre_num" value="'+review_num+'">';
			   modifyUI += '  <input type="hidden" name="mem_num" id="mmem_num" value="'+mem_num+'">';
			   modifyUI += '  <input type="hidden" name="res_num" id="mres_num" value="'+res_num+'">';
			   modifyUI += '  <textarea rows="3" cols="50" name="re_content" id="mre_content" class="rep-content"></textarea>';
			   modifyUI += '  <div id="mre_first"><span class="letter-count">1000/1000</span></div>';	
			   modifyUI += '  <div id="mre_second" class="align-right">';
			   modifyUI += '     <input type="submit" value="등록">';
			   modifyUI += '     <input type="button" value="취소" class="wre-reset">';
			   modifyUI += '  </div>';
			   modifyUI += '  <hr size="1" noshade width="90%">';
			   modifyUI += '</form>';
			   
			//이전에 이미 수정하는 댓글이 있을 경우 수정버튼을 클릭하면
			//숨김 sub-item을 환원시키고 수정폼을 초기화함
			initWriteForm();
			
			//지금 클릭해서 수정하고자 하는 데이터는 감추기
			//수정버튼을 감싸고 있는 div
			$(this).parent().hide();
			
			//수정폼을 수정하고자하는 데이터가 있는 div에 노출
			$(this).parents('.item').append(modifyUI);
			
			//입력한 글자수 셋팅
			var inputLength = $('#mre_content').val().length;
			var remain = 1000 - inputLength;
			remain += '/1000';
			
			//문서 객체에 반영
			$('#mre_first .letter-count').text(remain);		
		});
		//수정폼에서 취소 버튼 클릭시 수정폼 초기화
		$(document).on('click','.wre-reset',function(){
			initWriteForm();
		});
		//댓글 수정 폼 초기화
		function initWriteForm(){
			$('.sub-item').show();
			$('#mre_form').remove();
		}
		
		
		
		
		
		//------------------------대댓글 리스트----------------------------------------

/* 
 		function selectreData(pageNum, review_num){
		
		$.ajax({
			type:'get',
			data:{pageNum:pageNum,review_num:review_num},
			url:'../review/rereviewList.do',
			dataType:'json',
			cache:false,
			timeout:30000,
			success:function(param){
				 //로딩 이미지 감추기
				$('#loading').hide();
				count = param.count;
				rowCount = param.rowCount;
				var user_auth = ${user_auth};
				$(param.list).each(function(index,item){
					var output = '<div class="item">';
					output += '<div class="sub-item">';
					output +='   <p>' + item.re_content.replace(/</gi,'&lt;').replace(/>/gi,'&gt;') + '</p>';
					output += item.re_date; 
					if($('#mem_num').val()==item.mem_num){
						//로그인한 회원 번호가 댓글 작성자 회원 번호와 같으면
						output += ' <input type="button" data-num="'+item.rre_num+'" data-mem="'+item.mem_num+'" value="수정" class="modify-btn">';
						output += ' <input type="button" data-num="'+item.rre_num+'" data-mem="'+item.mem_num+'" value="삭제" class="delete-btn">';
					 }
					output += '  <hr size="1" noshade>';
					output += '</div>';
					output += '</div>';
					
					//문서 객체에 추가
					$('#output').append(output);
					
				});//end of each
				 
			 	//paging button 처리
				if(currentPage>=Math.ceil(count/rowCount)){
					//다음 페이지가 없음
					$('.paging-button').hide();
				}else{
					//다음 페이지가 존재
					$('.paging-button').show();
				},
			error:function(){
				alert('네트워크 오류 발생');
			}
		
		
	}
		}); 
		}
	
	 //다음 댓글 보기 버튼 클릭시 데이터 추가
	$('.paging-button input').click(function(){
		var pageNum = currentPage + 1;
		selectreData(pageNum,$('#camping_num').val());
	}); 
		 
		
 	//대댓글 리스트 버튼 클릭시 대댓글 리스트 노출
	$(document).on('click','.view-btn',function(){
		selectreData(pageNum,review_num);
	} 
		

  */
		
	});
</script>
<!-- 리뷰  시작 -->
<br><br>
<div class="page-main">
<hr size="1" width="100%" noshade="noshade">
<br><br>
	<h4 class="align-center" style="margin-bottom:8px;"><b>리뷰</b></h4>
<!-- 댓글 목록 출력 -->	
<hr size="1" width="100%" noshade="noshade">
	<div id="reply_div" class="align-center">
		<span class="reply-title" >후기 작성</span>
		<form id="re_form">
			<input type="hidden" name="camping_num" value="${param.camping_num}"
			       id="camping_num">
			<input type="hidden" name="mem_num" value="${user_num}" id="mem_num">
			<input type="hidden" name="res_num" value="1" id="mem_num">
			제목: <input type="text" name="title" value="${title}" id="title" 
			<c:if test="${empty user_num}">disabled="disabled"</c:if>
			 >
			<textarea rows="3" cols="50" name="content" 
			   id="re_content" class="rep-content" 
			   <c:if test="${empty user_num}">disabled="disabled"</c:if>
			   ><c:if test="${empty user_num}">로그인해야 후기를 작성할 수 있습니다.</c:if><%-- <c:if test="${empty res_num &&!empty user_num}">예약하신 분만 후기를 작성할 수 있습니다.</c:if> --%></textarea>
			
				<%-- <c:if test="${empty review.filename}">
				<img src="${pageContext.request.contextPath}/resources/images/blank.jpg" width="100" height="100" class="my-photo">
				</c:if> --%>
				<c:if test="${!empty review.filename}">
				<img src="${pageContext.request.contextPath}/review/photoView.do" width="100" height="100" class="my-photo">
				</c:if>
			
			
			<div class="align-center">
				<input type="file" value="파일 등록" id="upload" name="upload"
				 <c:if test="${empty user_num}">disabled="disabled"</c:if>
				  >
			</div>
			<div id="re_first">
				<span class="letter-count">1000/1000</span>
			</div>
			<div id="re_second" class="align-right">
				<input type="submit" value="전송">
			</div>
			
		</form>
	</div>
	<div id="output"></div>
	<div class="paging-button" style="display:none;">
		<input type="button" value="다음글 보기">
	</div>
	<div id="loading" style="display:none;">
		<img src="${pageContext.request.contextPath}/resources/images/ajax-loader.gif">
	</div>
</div>
<!-- 리뷰게시판 메인 끝 --> 