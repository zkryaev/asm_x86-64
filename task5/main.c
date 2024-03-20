#include <stdio.h>
#include "lab.h"
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

typedef struct image_size{
    int x;
    int y;
}image_size;

image_size getNewSize();
void NearNeigbour(int w1, int h1, int w2, int h2, int n, unsigned char* src, unsigned char* dst);

int main(){
    image_size new_image;
    new_image = getNewSize();
     
    //        Получить картинку и ее размеры
    int x, y, n, len_fname = 15;
    char* filename = (char*)malloc(len_fname);
    unsigned char* src = NULL;
    do{
        printf("Enter the name of picture:\n");
        scanf("%s", filename);
        
        src = stbi_load(filename, &x, &y, &n, 0);
    }while(src == NULL);

    image_size old_image = {x, y};
    
    // Обработка алгоритмом
    unsigned char* dst1 = (unsigned char*)malloc(new_image.x*new_image.y*n);
    unsigned char* dst2 = (unsigned char*)malloc(new_image.x*new_image.y*n);
    NearNeigbour(old_image.x, old_image.y, new_image.x, new_image.y, n, src, dst1); // Сишная реализация
    asm_NearNeighbour(old_image.x, old_image.y, new_image.x, new_image.y, src, dst2); // Ассемблерная 
    
    // Выгружаю изображение
    char* outname = "result_C.jpg";
    stbi_write_jpg(outname, new_image.x, new_image.y, n, dst1, 100);

          outname = "result_asm.jpg";
    stbi_write_jpg(outname, new_image.x, new_image.y, n, dst2, 100);

    stbi_image_free(src);
    stbi_image_free(dst1);
    stbi_image_free(dst2); 
    free(filename);
    
    return 0;
}

void NearNeigbour(int w1, int h1, int w2, int h2, int n, unsigned char* src, unsigned char* dst){ 
    double scaleX = (double)w1/w2;
    double scaleY = (double)h1/h2;
    int sourceX, sourceY, sourceIndex, targetIndex;
    
    for (int y=0; y < h2; y++) {
        for (int x=0; x < w2; x++) {
            sourceX =  (int)(x * scaleX);
            sourceY = (int)(y * scaleY);

            sourceIndex = (sourceY * w1 + sourceX) * n;
            targetIndex = (y * w2 + x) * n;

            dst[targetIndex] = src[sourceIndex];
            dst[targetIndex + 1] = src[sourceIndex + 1];
            dst[targetIndex + 2] = src[sourceIndex + 2];
        }
    }
}

image_size getNewSize(){
    image_size new_image;
    
    int width_new;
    int height_new;

    printf("Enter width_:\n");
    scanf("%d", &(width_new) );

    printf("Enter height_:\n");
    scanf("%d", &(height_new) );

    new_image.x = width_new;
    new_image.y = height_new;

    return new_image;
}