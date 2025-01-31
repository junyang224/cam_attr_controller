#include <iostream>
#include <sstream>
#include <fstream>

#include <math.h>

#include "irp_imgeval++/img_eval.h"


using namespace std;

int main(int argc, char** argv)
{

    cv::Mat eval_img; 
    Img_eval eval;
    eval_img = cv::imread ("../../data/2.png", 1);
	Mat resized;
	cv::resize (eval_img, eval_img, cv::Size(188, 120));
    if (!eval_img.data) {
        std::cout << "Error <path_to_image>" << std::endl;
        return -1;
    }
    double ewg = eval.calc_img_ent_grad (eval_img, true);

    cout << "ewg = " << ewg << ", " << eval_img.size() << endl;
    cv::resize (eval_img, eval_img, cv::Size(160, 120));
    cv::imshow("eval_img", eval_img);
    cv::waitKey();
}
