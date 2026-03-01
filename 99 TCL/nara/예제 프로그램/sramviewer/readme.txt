######################################################################

                        SRAM Viewer     Ver 1.0

         System IC R&D in Hyundai Electronics Inc. Copryright (c), 1998

                                                by Nara Won

######################################################################

1. 시스템 요구 사항

        - OS
                - Windows 95 or NT 또는
                - UNIX with X Windows
        - Required Software
                - Tcl/Tk 8.0 or later

2. 프로그램 인스톨

        - Windows 95 or NT
                - 적당한 Folder를 만든다. 
                        예)  C:\CADUtil
                - sramview.zip 파일을 그 Folder내에서 압축을 푼다.
                        - pkunzip 혹은 winzip 이용

        - UNIX
                - 적당한 directory를 만든다.
                        예) ~/CADUtil
                - sramview.tar.gz 파일의 압축을 해제 한다.
                        - gunzip sramview.tar.gz*

                        - sramview.tar.gz 에서 sramview.tar로 바뀜
                - sramview.tar 파일에서 파일들을 추출한다.
                        - tar xvf sramview.tar ~/CADUtil

3. 배포되는 파일 리스트

        - ~/CADUtil에 프로그램을 인스톨 했을 경우
        - ~/CADUtil/sramview
                - sramView.tcl    
                        - SRAM Viewer main program file
                - sramView.resource
                        - SRAM Viewer resource file
                - readme.txt
                        - This file
                - sample.srv
                        - Sample Data
        - ~/CADUtil/GUI
                - GUI.tcl
                        - SRAM Viewer GUI package
                - pkgIndex.tcl
                        - index file of SRAM Viewer GUI package routines 



4. 프로그램 사용 방법

        - 프로그램 시작

                - UNIX
                        % sramView.tcl [data_file_name]
                - Windows
                        C:> wish sramView.tcl [data_file_name]
                        - Tcl/Tk의 버전에 따라 Tcl/Tk Shell 프로그램 이름이
                        달라질 수 있다.  예)  wish -> wish80
                        - sramView.tcl을 Double Click하여 실행할 수 있다.
                        - sramView.tcl의 단축아이콘을 만들어 놓고 이것을
                        Double Click하여도 실행할 수 있다.
                - command line에서 데이타 파일 이름을 줄 경우 그 파일이
                자동으로 Open된다.

       - 메뉴
                - File
                        - Open
                                - 새로운 데이타 파일을 Open한다.
                        - Close
                                - 현재 보고 있는 데이타 File을 Close한다.
                        - Print
                                - 현재 윈도우의 내용을 postscript 파일로 만든다.
                                - !!주의!! 윈도우에 보이는 부분만 출력됨
                        - Quit
                                - Program을 종료한다.
                - View
                        - ZoomIn
                                - 확대하여 본다.
                                - 원본 이미지의 4배까지 확대 가능하다.
                                - 한번 누를 때 마다 25%씩 확대비율을 높인다.
                        - ZoomOut
                                - 축소하여 본다.
                                - 원본 이미지의 1/4까지 축소 가능하다.
                                - 한번 누를 때 마다 25%씩 확대비율을 줄인다.
                - Help
                        - About
                                - 프로그램에 대한 정보를 보여준다.
        
5. 데이터 파일 형식

        - 확장자

                - *.srv

        - 파일 내용

                - comment
                        - #으로 시작하는 라인은 comment로 간주
                        - 화면 하단에 모든 comment line들이 그대로 출력될 것임

        - SRAM 정보

                - info_name = value
                        - info_name의 종류
                                - xunit, yunit : Cell의 실제 길이 (단위 ?)
                                - xnum, ynum : Cell의 갯수
                - 한 줄에 정보 하나씩만
                - 위의 4가지 정보는 반드시 제공되어야 함

        - Failed Cell 정보 블럭

                - 색깔 정보

                        - color = color_value : comment
                        - color_value에 가능한 값
                                - red, green, blue, grey, black
                                - yellow, magenta, violet, orange, 
                                - pink, purple, brown
                        - comment는 화면 하단에 color box다음에 출력될 것임
                        - 색깔 정보는 위치 정보보다 앞에 위치해야 함
                        - 색깔 정보 다음에 나오는 위치정보의 Cell들은 
                        모두 그 색으로 채워짐

                - 위치 정보

                        - Xi, Yi
                                - Xi : X index
                                - Yi : Y index
                        - 한 줄에 한 Cell의 정보만

                        - 위치정보 규약		

                                - 가장 왼쪽 가장 아래쪽이 (1,1)로 간주
                                - 오른쪽이 X+ 방향
                                - 위쪽이 Y+ 방향

                - 기타
	
                        - space, tab, blank line은 가독성을 높이기 위해 
                        적절히 사용해도 무방
                        - 각 정보가 나오는 순서는 Failed Cell정보를 제외하고는 
                        어디에 위치해도 무방함
                        - Failed Cell 정보 블럭 자체는 어디에 위치해도 무방
                        - Failed Cell 정보 블럭 내에서 Color정보와 위치 정보의 
                        순서는 지켜야 함

                - 데이터 파일 예제는 함께 배포된 "sample.srv"파일 참조
